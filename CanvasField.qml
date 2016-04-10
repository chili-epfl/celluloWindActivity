import QtQuick 2.0
import QtCanvas3D 1.0
import QtPositioning 5.2
import Cellulo 1.0
import "renderer.js" as GLRender
Item {
    width: parent.width
    height: parent.height
    property variant robot: null
      property variant playground: playground
    property variant windfield: windField
    property int fieldWidth: 2418
    property int fieldHeight: 950

    visible: false
    Canvas3D {
        id: windField
        width: parent.width
        height: parent.height


        property int menuMargin: 50
        property int fieldWidth: 2418
        property int fieldHeight: 950

        property int robotMinX: (windField.width - windField.fieldWidth)/2
        property int robotMinY: (windField.height - windField.fieldHeight)/2
        property int robotMaxX: robotMinX + windField.fieldWidth
        property int robotMaxY: robotMinY + windField.fieldHeight

        //Game UI variables, kept here so that all components can have access to them
        property bool paused: true
        property bool drawPressureGrid: true
        property bool drawForceGrid: true
        property bool drawLeafVelocityVector: true
        property bool drawLeafForceVectors: true
        property bool drawPrediction: false
        property int currentAction: 0

        //Set the leaves here
        property variant leaves: [testLeaf]
        property int numLeaves: 1

        property int nblifes: 3
        property int game: 3

        function addPressurePoint(r,c,pressureLevel) {
            console.log('called here')
            pressurefield.addPressurePoint(r,c,pressureLevel)
        }

        function addPressurePointCoord(y,x,pressureLevel) {
            console.log('called here')
            var r = y
            var c = x
            pressurefield.addPressurePoint(r,c,pressureLevel)
        }
        function setInitialConfiguration(){
            setObstaclesfromZones()
            //Set test leaf info

            var startp = playground.zones[0]["path"]
            var center = getCenterFromPoly(startp)
            var startcoords = fromPointToCoords((center.x*fieldHeight-20)/pressurefield.numRows,(center.y*fieldWidth)/pressurefield.numCols)
            console.log("startpoints")
            //startcoords =  Qt.point(50,50)
            console.log(startcoords.x, startcoords.y)
            testLeaf.leafX = startcoords.x
            testLeaf.leafY = startcoords.y
            testLeaf.leafXV = 0
            testLeaf.leafYV = 0
            testLeaf.leafMass = 2
            testLeaf.leafSize = 150
            testLeaf.leafXF = 0
            testLeaf.leafYF = 0
            testLeaf.leafXFDrag = 0
            testLeaf.leafYFDrag = 0
            testLeaf.collided = false

            pauseSimulation()
        }

        function setInitialTestConfiguration(){

            //Set pressure point
            pressurefield.addPressurePoint(0,0,3)
            pressurefield.addPressurePoint(14,0,3)
            pressurefield.addPressurePoint(0,25,3)
            pressurefield.addPressurePoint(14,25,3)
            pressurefield.addPressurePoint(7,12,-3)
            pressurefield.addPressurePoint(8,12,-3)
            pressurefield.addPressurePoint(7,13,-3)
            pressurefield.addPressurePoint(8,13,-3)


            //Set test leaf info
            testLeaf.leafX = 10*pressurefield.xGridSpacing
            testLeaf.leafY = pressurefield.height/2
            testLeaf.leafXV = 0
            testLeaf.leafYV = 0
            testLeaf.leafMass = 1
            testLeaf.leafSize = 150
            testLeaf.leafXF = 0
            testLeaf.leafYF = 0
            testLeaf.leafXFDrag = 0
            testLeaf.leafYFDrag = 0
            testLeaf.collided = false

            pauseSimulation()

        }

        // - Set obstacle spots
        function setObstacles() {
            pressurefield.pressureGrid[10][30][6] = 0
        }

        // - Set the obstales from the obstaclezone list of ZonesF
        function setObstaclesfromZones(){
            // TODO : PLACEMENT NOT ACCURATE OF THE ZONES
            //console.log("start zoning")
            var zones = playground.zones
            for (var i = 0; i < zones.length; i++) {

                if(zones[i]["name"].indexOf("obstacle")===0 ||zones[i]["name"].indexOf("cloud")===0){
                    console.log(zones[i]["name"])
                    var pathcoord = []
                    var minPX = pressurefield.numCols;var minPY = pressurefield.numRows;var maxPX = 0;var maxPY = 0;
                    for( var j =0 ; j< zones[i]["path"].length; j++){
                        var point  = zones[i]["path"][j]
                        var coord = fromPointToCoords(point.x,point.y)

                        minPX = Math.min(minPX,coord.x)
                        maxPX = Math.max(maxPX,coord.x)
                        minPY = Math.min(minPY,coord.y)
                        maxPY = Math.max(maxPY,coord.y)
                        pathcoord.push(Qt.point(coord.y,coord.x))
                        pressurefield.pressureGrid[coord.y][coord.x][6] = 0

                    }
                    // - try to fill the zone with obstacle
                    // TODO : NOT COVERING THE WHOLE ZONE
                    /*for (var px = minPX ; px<maxPX; px++){
                        for (var py = minPY ; py<maxPY ; py++){
                            if(isPointInPoly(pathcoord, Qt.point(py,px)))
                                pressurefield.pressureGrid[py][px][6] = 0
                        }
                    }*/
                }
            }
        }

        function pauseSimulation() {
            paused = false;
            controls.togglePaused()
        }


        function initGame(){

        }
        ////////////////////// UTILS FUNCTIONS
        // - return the center of a polygone
        function getCenterFromPoly(poly){
            var minx= poly[0].x, miny= poly[0].y, maxx = poly[0].x, maxy = poly[0].y;
            for(var i = 0 ; i <poly.length; i++){
                minx = Math.min(minx, poly[i].x);
                miny= Math.min(miny, poly[i].y);
                maxx= Math.max(maxx, poly[i].x);
                maxy= Math.max(maxy, poly[i].y);
                console.log(poly[i].x, poly[i].y)
            }
            console.log(maxy, miny ,maxx, minx)
            return Qt.point((maxx+minx)/2,(maxy+miny)/2)
        }

        // - return true if the point is in the polygone poly
        function isPointInPoly(poly, pt){
            for(var c = false, i = -1, l = poly.length, j = l - 1; ++i < l; j = i){
                //console.log(poly[i].x,poly[i].y )
                if(
                        ((poly[i].y <= pt.y && pt.y < poly[j].y) || (poly[j].y <= pt.y && pt.y < poly[i].y))
                        && (pt.x < (poly[j].x - poly[i].x) * (pt.y - poly[i].y) / (poly[j].y - poly[i].y) + poly[i].x)
                        && (c = !c));
                //console.log(c)
                return c;
            }
        }

        // - transform a point (between 0 and 1) to coordinates in the pressureGrid
        function fromPointToCoords(ptx,pty){
            return   Qt.point(Math.round(ptx*pressurefield.numCols),Math.round(pty*pressurefield.numRows));
        }

        ////////////////////// GL STUFFS
        onInitializeGL: {
            GLRender.initializeGL(windField, pressurefield, leaves, numLeaves)
        }

        //Since we do no update the pressure grid while the simulation is running, the only thing we have to update then are the leaves
        onPaintGL: {
            if (!paused) {
                for (var i = 0; i < numLeaves; i++)
                    leaves[i].updateLeaf()
            }
            GLRender.paintGL(pressurefield, leaves, numLeaves)
        }

        function setPressureFieldTextureDirty() {
            GLRender.pressureFieldUpdated = true;
        }

        Component.onCompleted: {
            pressurefield.resetWindField()
            setInitialConfiguration()

        }

        ////////////////////// STATES
        states:[
            State{
                name: "lost"
                PropertyChanges {target: ontopPanel; state:"playagain"}
                PropertyChanges {target: ontopPanel; visible:true}
                PropertyChanges {target: windField; nblifes: (windField.nblifes-1)}
            },
            State{
                name: "over"
                PropertyChanges {target: ontopPanel; state:"gameover"}
                PropertyChanges {target: ontopPanel; visible:true}
                PropertyChanges {target: windField; nblifes: (windField.nblifes-1)}
            },
            State{
                name: "win"
                PropertyChanges {target: ontopPanel; state:"winr"}
                PropertyChanges {target: ontopPanel; visible:true}
                PropertyChanges {target: windField; nblifes:windField.nblifes}
            },
            State{
                name: "ready"
                PropertyChanges {target: ontopPanel; visible:false}
                PropertyChanges {target: windField; nblifes:windField.nblifes}
            }
        ]



        ////////////////////// EMBEDDED ITEMS
        PressureField {
            width: windField.fieldWidth
            height: windField.fieldHeight
            x: windField.robotMinX
            y: windField.robotMinY
            id: pressurefield
        }

        Leaf {
            id: testLeaf
            field: pressurefield
            robot: parent.parent.robot
            allzones: playground
            controls: parent.controls
        }

    }

    ////////////////////// TOP PANEL
    UIPanel {
        //anchors.fill: parent
        id: controls
        robot: parent.robot
        windfield: windField
        width: parent.width
        height: parent.height /5
        playground: playground
    }


    Rectangle {
        id: ontopPanel
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width/2
        height:  parent.height/2
        color: Qt.rgba(1,1,1,0.6)
        radius:110
        visible:false
            Text {
                id:thetext
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: button.top
                font.family: "Helvetica"
                font.pointSize: 20
                font.bold: true
                text:""
            }

            Item {
                id: button
                width: 100
                height: 100
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.verticalCenter: parent.verticalCenter
                Image {
                    id: backgroundImage
                    anchors.fill: parent
                    source:  "assets/buttons/reset.png"
                MouseArea {
                    anchors.fill: backgroundImage
                    onClicked: { pressurefield.resetWindField()
                        windfield.setInitialConfiguration()
                        windfield.setPressureFieldTextureDirty()
                        windfield.pauseSimulation()
                        windfield.state = "ready"
                    }

                }
                }
            }

            states:[
                State{
                    name: "playagain"
                    PropertyChanges {target: thetext; text:"Play again?"}
                    PropertyChanges {target: backgroundImage; source:  "assets/buttons/reset.png"}
                },
                State{
                    name: "winr"
                    PropertyChanges {target: thetext; text:"You made it!"}
                    PropertyChanges {target: backgroundImage; source:  "assets/buttons/reset.png"}
                    //todo add time and total points
                },
                State{
                    name: "wins"
                    PropertyChanges {target: thetext; text:"You made it!"}
                    PropertyChanges {target: backgroundImage; source:  "assets/buttons/gameover.png"}
                    //todo add time and total points
                },
                State{
                    name: "gameover"
                    PropertyChanges {target: thetext; text:"Game Over"}
                    PropertyChanges {target: backgroundImage; source:  "assets/buttons/gameover.png"}
                },
                State{
                    name: "info"
                    PropertyChanges {target: thetext; text:"Here some infos"}
                    PropertyChanges {target: backgroundImage; source:  "assets/buttons/info.png"}
                }
            ]

    }
    ////////////////////// BOTTOM PANEL
    Rectangle {
        id: stockView
        y: parent.height -  controls.height
        anchors.left : windField.left
        width: controls.width
        height:  controls.height
        color: Qt.rgba(1,1,1,0.6)
        radius:155

        Row {
            id:rowPressure
            width:parent.width
            height: parent.height
            spacing: 50

            //Pressure points in the stock
            PressurePoint{
                id: pressurePoint1
                field: pressurefield
                ilevel: 2
            }
            PressurePoint{
                id: pressurePoint10
                field: pressurefield
                ilevel: -2
            }
            PressurePoint{
                id: pressurePoint2
                field: pressurefield
                ilevel: -1
            }
            PressurePoint{
                id: pressurePoint3
                field: pressurefield
                ilevel: 1
            }
        }
    }
}
