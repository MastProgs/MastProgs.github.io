window.addEventListener("load", main, false);
window.addEventListener("keydown", onkeydown, false);

//기본 설정 셋팅
var UP = 1;
var RIGHT = 2;
var LEFT = 3;
var Down = 4;

var state = true;
var score = 0;
var highscore = 0;

var saveFileName = "snakeSave.txt";

//var fso = new ActiveXObject("Scripting.FileSystemObject");
//var filename = "score.txt"
//if (!fso.FileExists(filename)) {
//    fso.CreateTextFile(filename, true);
//    fso.write(0);
//    fso.close();
//}
//else {
//    fso.OpenTextFile(filename, 1);
//    highscore = fso.ReadAll();
//    fso.close();
//}

var map = new Array(80);
for (var i = 0 ; i < 80; ++i) {
    map[i] = new Array(60);
}

var moveHistory = new Array();
moveHistory.push(LEFT);

var foodcount = 0
var food = false;

function loadingMessage() {
    var theCanvas = document.getElementById("GameCanvas");
    var Context = theCanvas.getContext("2d");

    Context.font = "30px Arial"
    Context.fillStyle = "#000000";

    if (state) {
        Context.fillText("Loading...", 340, 310);
    }
    else {
        Context.fillText("Game Over", 320, 290);
        Context.font = "20px Arial"
        Context.fillText("Restart ( Press Space Key )", 275, 320);
    }
}

function drawScreen() {
    var theCanvas = document.getElementById("GameCanvas");
    var Context = theCanvas.getContext("2d");

    Context.fillStyle = "#000000";
    for (var i = 0; i < 80; ++i) {
        for (var j = 0; j < 60; ++j) {
            if (map[i][j] == 1) {
                Context.fillStyle = "#000000";
                Context.fillRect(i * 10, j * 10, 10, 10);
            }
            else if (map[i][j] == 2) {
                var rand = Math.floor(Math.random() * 100);
                rand = rand % 5;

                if (rand == 0) {
                    Context.fillStyle = "#ffff00";
                }
                else if (rand == 1) {
                    Context.fillStyle = "#ff0000";
                }
                else if (rand == 2) {
                    Context.fillStyle = "#0000ff";
                }
                else if (rand == 3) {
                    Context.fillStyle = "#00ffff";
                }
                else {
                    Context.fillStyle = "#ff00ff";
                }
                Context.fillRect(i * 10, j * 10, 10, 10);
                Context.strokeRect(i * 10, j * 10, 10, 10);
            }
            else {
                Context.strokeStyle = "#F0F0F0";
                Context.strokeRect(i * 10, j * 10, 10, 10);
            }
        }
    }
}

function scoring() {
    var theScore = document.getElementById("scor");

    theScore.style.fontSize = "35px";
    theScore.innerHTML = "Score = " + score;
}

function highscoring() {
    var theScore = document.getElementById("high");
    var playerName = "";
    
    if (highscore == 0) {
        var fileObject = new ActiveXObject("Scripting.FileSystemObject");
        if (fileObject.FileExists(saveFileName)) {
            var fOpen = fileObject.OpenTextFile(saveFileName, 1);
            highscore = fOpen.Readline();
            playerName = fOpen.Readline();
        }
    }

    theScore.style.fontSize = "35px";
    theScore.innerHTML = "High Score = " + highscore + ", The Player = " + playerName;
}

function clearCanvas() {
    var theCanvas = document.getElementById("GameCanvas");
    var Context = theCanvas.getContext("2d");

    Context.clearRect(0, 0, theCanvas.width, theCanvas.height);
    Context.beginPath();
}

function Player(x, y, direction) {
    this.x = x;
    this.y = y;
    this.direction = direction;
}

var player = new Player(20, 30, RIGHT);

function mapDefault() {
    for (var i = 0; i < 80; ++i) {
        for (var j = 0; j < 60; ++j) {
            map[i][j] = 0;
        }
    }
}

function movePoint() {
    var tempx = player.x;
    var tempy = player.y;
    for (var i = 0; i < moveHistory.length; ++i) {
        if (moveHistory[i] == UP) {
            ++tempy;
        }
        else if (moveHistory[i] == Down) {
            --tempy;
        }
        else if (moveHistory[i] == LEFT) {
            ++tempx;
        }
        else if (moveHistory[i] == RIGHT) {
            --tempx;
        }
    }
    map[tempx][tempy] = 0;
}

function logic() {
    if (player.direction == UP) {
        if (player.y > 0) {
            --player.y;

            if (map[player.x][player.y] == 2) {
                moveHistory.unshift(UP);
                if (foodcount == 1) {
                    score += 400;
                }
                foodcount--;
                score += 100;
                //food = false;
            }
            else if (map[player.x][player.y] == 1) {
                state = false;
            }
            else {
                moveHistory.unshift(UP);
                movePoint();
                moveHistory.pop();
            }
        }
        else {
            //death
            state = false;
        }
    }
    else if (player.direction == RIGHT) {
        if (player.x < 79) {
            ++player.x;

            if (map[player.x][player.y] == 2) {
                moveHistory.unshift(RIGHT);
                if (foodcount == 1) {
                    score += 400;
                }
                foodcount--;
                score += 100;
                //food = false;
            }
            else if (map[player.x][player.y] == 1) {
                state = false;
            } else {
                moveHistory.unshift(RIGHT);
                movePoint();
                moveHistory.pop();
            }
        }
        else {
            //death
            state = false;
        }
    }
    else if (player.direction == LEFT) {
        if (player.x > 0) {
            --player.x;

            if (map[player.x][player.y] == 2) {
                moveHistory.unshift(LEFT);
                if (foodcount == 1) {
                    score += 400;
                }
                foodcount--;
                score += 100;
                //food = false;
            }
            else if (map[player.x][player.y] == 1) {
                state = false;
            } else {
                moveHistory.unshift(LEFT);
                movePoint();
                moveHistory.pop();
            }
        }
        else {
            //death
            state = false;
        }
    }
    else if (player.direction == Down) {
        if (player.y < 59) {
            ++player.y;

            if (map[player.x][player.y] == 2) {
                moveHistory.unshift(Down);
                if (foodcount == 1) {
                    score += 400;
                }
                foodcount--;
                score += 100
                //food = false;
            }
            else if (map[player.x][player.y] == 1) {
                state = false;
            } else {
                moveHistory.unshift(Down);
                movePoint();
                moveHistory.pop();
            }
        }
        else {
            //death
            state = false;
        }
    }
}

function foodMaker() {
    if (food == false) {
        var tempx = Math.floor(Math.random() * 100 % 80);
        var tempy = Math.floor(Math.random() * 100 % 80);

        if (map[tempx][tempy] != 0) {
            food = false;
        }
        else {
            map[tempx][tempy] = 2;
            foodcount++;
            food = true;
        }
    }
}

function foodOn() {
    food = false;
}

// 먹이 주기용 단순 합산
var count = 0;

function re() {
    if (state) {
        ++count;
        clearCanvas();

        if (count % 80 == 0) {
            foodOn();
        }

        foodMaker();
        logic();

        map[player.x][player.y] = 1;
        scoring();
        highscoring();

        drawScreen();
    }
    else {
        clearCanvas();
        loadingMessage();
    }
}

function main() {
    //게임 초기 셋팅
    loadingMessage();
    mapDefault();
    map[player.x][player.y] = 1;

    //반복
    intervalID = setInterval(re, 40);
}

function restarting() {
    state = true;
    if (highscore < score) {
        highscore = score;        
    }
    score = 0;
    count = 0;
    foodcount = 0;

    mapDefault();

    var tempresult = 1;
    while (tempresult) {
        tempresult = moveHistory.pop();
    }
    moveHistory.push(LEFT);

    food = false;
    player.x = 20;
    player.y = 30;
    player.direction = RIGHT;
}

// 너무 빠른 입력 시, (이동 하기도 전에 이동 상태가 바뀌는 경우 ) 으앙 쥬금
function onkeydown(e) {
    switch (e.keyCode) {
        case 37:
            if (player.direction != RIGHT) {
                player.direction = LEFT;
            }
            break;
        case 39:
            if (player.direction != LEFT) {
                player.direction = RIGHT;
            }
            break;
        case 38:
            if (player.direction != Down) {
                player.direction = UP;
            }
            break;
        case 40:
            if (player.direction != UP) {
                player.direction = Down;
            }
            break;
        case 32:    // 재시작, space
            intervalID = clearInterval(re);
            restarting();
            break;
        default:
            break;
    };
}
