import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import Quickshell.Hyprland
import QtQuick
import QtQuick.Layouts
import Quickshell.Services.UPower

PanelWindow {
    id: root

    // Theme
    property color colBg: "#261a1a"
    property color colFg: "#d6a9a9"
    property color colMuted: "#6a4444"
    property color colRed: "#d70d0d"
    property color colCoral: "#f77a7a"
    property color colYellow: "#e08268"
    property string fontFamily: "JetBrainsMono Nerd Font"
    property int fontSize: 14

    // System data
    //property real percentage: UPower.displayDevice.percentage
    property int batteryPercent: 0
    property int cpuUsage: 0
    property int memUsage: 0
    property var lastCpuIdle: 0
    property var lastCpuTotal: 0

    // Processes and timers here...

    anchors.top: true
    anchors.left: true
    anchors.right: true
    implicitHeight: 30
    color: root.colBg

    RowLayout {
        anchors.fill: parent
        anchors.margins: 8
        spacing: 8

        // Workspaces
        Repeater {
            model: 9
            Text {
                property var ws: Hyprland.workspaces.values.find(w => w.id === index + 1)
                property bool isActive: Hyprland.focusedWorkspace?.id === (index + 1)
                text: index + 1
		color: isActive ? root.colRed: (ws ? root.colCoral : root.colMuted)
                font { family: root.fontFamily; pixelSize: root.fontSize; bold: true }
                MouseArea {
                    anchors.fill: parent
                    onClicked: Hyprland.dispatch("workspace " + (index + 1))
                }
            }
        }

        Item { Layout.fillWidth: true }

	// Battery
	Process {
		id: batteryProc
		property real batteryPercentage: UPower.displayDevice.percentage
		//root.batteryPercent = Math.round(100 * batteryPercentage)
		//Component.onCompleted: running = true
	}
	Text{
		text: "Battery: " + batteryPercent + "%"
		color: root.colRed
		font {family: root.fontFamily; pixelSize: root.fontSize; bold: true}
	}

	Rectangle { width: 1; height: 16; color: root.colMuted }

	
	// CPU
	Process {
    		id: cpuProc
   		 command: ["sh", "-c", "head -1 /proc/stat"]
   		 stdout: SplitParser {
    		    onRead: data => {
            		if (!data) return
            		var p = data.trim().split(/\s+/)
           		 var idle = parseInt(p[4]) + parseInt(p[5])
          		  var total = p.slice(1, 8).reduce((a, b) => a + parseInt(b), 0)
           		 if (lastCpuTotal > 0) {
            		    cpuUsage = Math.round(100 * (1 - (idle - lastCpuIdle) / (total - lastCpuTotal)))
          		  }
          		  lastCpuTotal = total
         		   lastCpuIdle = idle
      		  }
  		  }
  		  Component.onCompleted: running = true
		}
	
        Text {
            text: "CPU: " + cpuUsage + "%"
            color: root.colYellow
            font { family: root.fontFamily; pixelSize: root.fontSize; bold: true }
        }

        Rectangle { width: 1; height: 16; color: root.colMuted }

	// Memory
	Process {
		id: memProc
		command: ["sh", "-c", "free | grep Mem"]
		stdout: SplitParser {
			onRead: data => {
				if (!data) return
				var parts = data.trim().split(/\s+/)
				var total = parseInt(parts[1]) || 1
				var used = parseInt(parts[2]) || 0
				memUsage = Math.round(100 * used / total)
			}
		}
		Component.onCompleted:running = true
	}

        Text {
            text: "Mem: " + memUsage + "%"
            color: root.colRed
            font { family: root.fontFamily; pixelSize: root.fontSize; bold: true }
        }

        Rectangle { width: 1; height: 16; color: root.colMuted }

        // Clock
        Text {
            id: clock
            color: root.colCoral
            font { family: root.fontFamily; pixelSize: root.fontSize; bold: true }
            text: Qt.formatDateTime(new Date(), "ddd, MMM dd - HH:mm")
            Timer {
                interval: 1000
                running: true
                repeat: true
                onTriggered: clock.text = Qt.formatDateTime(new Date(), "ddd, MMM dd - HH:mm")
            }
        }

	Timer {
		interval: 2000
		running: true
		repeat: true
		onTriggered: {
			memProc.running = true
			cpuProc.running = true
			batteryProc.running = true

		}
	}
}
}

