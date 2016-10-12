from matplotlib import pyplot as p
from PySide import QtGui, QtCore

import matplotlib
import matplotlib.animation as animation
import sys
# specify the use of PySide
matplotlib.rcParams['backend.qt4'] = "PySide"

# import the figure canvas for interfacing with the backend
from matplotlib.backends.backend_qt4agg import FigureCanvasQTAgg as FigureCanvas
from matplotlib.figure import Figure

import numpy as np

import udp_utils
import struct
import threading
from datetime import datetime

class Ui_MainWindow(object):
    def setupUi(self, MainWindow):
        MainWindow.setObjectName("MainWindow")
        MainWindow.resize(800, 500)
        MainWindow.setWindowTitle("PySDLab")
        self.centralwidget = QtGui.QWidget(MainWindow)
        self.centralwidget.setObjectName("centralwidget")
        self.horizontalLayout = QtGui.QHBoxLayout(self.centralwidget)
        self.horizontalLayout.setObjectName("horizontalLayout")

        self.ctrlwidget = QtGui.QWidget()
        self.verticalLayout = QtGui.QVBoxLayout(self.ctrlwidget)
        self.verticalLayout.setObjectName("verticalLayout")
        sizePolicy = QtGui.QSizePolicy(QtGui.QSizePolicy.Maximum, QtGui.QSizePolicy.Fixed)
        sizePolicy.setHorizontalStretch(0)
        sizePolicy.setVerticalStretch(0)
        self.ctrlwidget.setSizePolicy(sizePolicy)
        self.horizontalLayout.addWidget(self.ctrlwidget)

        self.pushButton = QtGui.QPushButton(self.centralwidget)
        sizePolicy = QtGui.QSizePolicy(QtGui.QSizePolicy.Maximum, QtGui.QSizePolicy.Fixed)
        sizePolicy.setHorizontalStretch(0)
        sizePolicy.setVerticalStretch(0)
        sizePolicy.setHeightForWidth(self.pushButton.sizePolicy().hasHeightForWidth())
        self.pushButton.setSizePolicy(sizePolicy)
        self.pushButton.setMaximumSize(QtCore.QSize(150, 16777215))
        self.pushButton.setObjectName("pushButton")
        self.pushButton.setText("Save")
        self.verticalLayout.addWidget(self.pushButton)

        self.pushButton1 = QtGui.QPushButton(self.centralwidget)
        sizePolicy = QtGui.QSizePolicy(QtGui.QSizePolicy.Maximum, QtGui.QSizePolicy.Fixed)
        sizePolicy.setHorizontalStretch(0)
        sizePolicy.setVerticalStretch(0)
        sizePolicy.setHeightForWidth(self.pushButton1.sizePolicy().hasHeightForWidth())
        self.pushButton1.setSizePolicy(sizePolicy)
        self.pushButton1.setMaximumSize(QtCore.QSize(150, 16777215))
        self.pushButton1.setObjectName("pushButton1")
        self.pushButton1.setText("Pause")
        self.verticalLayout.addWidget(self.pushButton1)
        
        self.mplFrame = MplFrame(self.centralwidget)
        self.mplFrame.setObjectName("MplFrame")
        self.horizontalLayout.addWidget(self.mplFrame)
        
        MainWindow.setCentralWidget(self.centralwidget)
        
        QtCore.QMetaObject.connectSlotsByName(MainWindow)

class MplFrame(QtGui.QFrame):
    
    def __init__(self, parent=None):
        super(MplFrame, self).__init__(parent)
        self.setFrameShape(QtGui.QFrame.StyledPanel)
        #self.setFrameShadow(QtGui.QFrame.Raised)
        self.parent = parent
        self.mplWidget = MplWidget(self)
        
    def resizeEvent(self, event):
        self.mplWidget.setGeometry(self.rect())
        
class MainWindow(QtGui.QMainWindow):
    def __init__(self, parent=None):
        super(MainWindow, self).__init__(parent)
        self.ui = Ui_MainWindow()
        self.ui.setupUi(self)
        self.ui.pushButton.clicked.connect(self.save_data)
        self.ui.pushButton1.clicked.connect(self.pause_anim)
        self.animation = self.ui.mplFrame.mplWidget.animate()

    def save_data(self):
        r = self.ui.mplFrame.mplWidget.shared_data.read()
        f = Figure()
        a = f.add_subplot(111)
        a.set_xlabel("time (us)")
        a.set_ylabel("Voltage (V)")
        a.set_autoscaley_on(False)
        a.set_ylim([-2, 2])
        a.set_xlim([0, 1])
        #x = [i for i in range(256)]
        #a.plot(x, r[0::2])
        #a.plot(x, r[1::2])
        x = [i * 4 / 1000 for i in range(256)]
        a.plot(x, [i * 2 / 32768 for i in r[0::2]])
        a.plot(x, [i * 2 / 32768 for i in r[1::2]])
        c = matplotlib.backends.backend_agg.FigureCanvasAgg(f)
        c.print_figure("pysdlab-" + datetime.now().strftime('%Y-%m-%d-%M-%H-%S') + ".png")

    def pause_anim(self):
        self.ui.mplFrame.mplWidget.pause ^= True
        if self.ui.mplFrame.mplWidget.pause:
            self.ui.pushButton1.setText("Start")
        else:
            self.ui.pushButton1.setText("Pause")


class LockedSharedObject:
    
    def __init__(self):
        self.lock = threading.Lock()
        self.raw_data = [i for i in range(512)]

    def write(self, d):
        with self.lock:
            self.raw_data = list(d)

    def read(self):
        with self.lock:
            return list(self.raw_data)

class MplWidget(FigureCanvas):
    def __init__(self, parent=None):
        self.figure = Figure()
        super(MplWidget, self).__init__(self.figure)
        self.setParent(parent)
        
        self.axes = self.figure.add_subplot(111)
        self.axes.set_xlabel("time (us)")
        self.axes.set_ylabel("Voltage (V)")
        self.axes.set_autoscaley_on(False)
        self.axes.set_ylim([-2, 2])
        self.axes.set_xlim([0, 1])
        self.frames = 5
        self.pause = False
        self.shared_data = LockedSharedObject()
        
        dummy = [i * 4 / 1000 for i in range(256)]
        self.line0, = self.axes.plot(dummy, dummy)
        self.line1, = self.axes.plot(dummy, dummy)

        
    def func_plot(self, z):
        u = udp_utils.udp_utils()
        d = u.send_recv('10.0.0.1', 16385, struct.pack('>I', 0))
        r = struct.unpack('>'+'h'*512, d)
        u.close()
        ydata0 = [i * 2 / 32768 for i in r[0::2]]
        ydata1 = [i * 2 / 32768 for i in r[1::2]]
        #xdata = [i * 4 for i in range(256)]
        xdata = [i * 4 / 1000 for i in range(256)]
        if not self.pause:
            self.shared_data.write(r)
            self.line0.set_data(xdata, ydata0)
            self.line1.set_data(xdata, ydata1)

    def animate(self):
        return animation.FuncAnimation(
                    fig=self.figure, func=self.func_plot, frames=self.frames,
                    interval=1000.0 / self.frames, blit=False)

if __name__ == "__main__":
    app = QtGui.QApplication(sys.argv)
    mw = MainWindow()
    mw.show()
    sys.exit(app.exec_())
