"use strict";

const { exec } = require("child_process");
const http = require("http");
const url = require("url");

const port = 8703;
const keys = {
    "browser-key": ["title", "delay 0", "-key",],
    "radio-nv"   : ["title",                   ],
    "notify"     : ["message",                 ],
    "mouse-click": ["x", "y",                  ],
    "mac-scene"  : [                           ],
};

http
    .createServer((request, response) => {
        const params = url.parse(request.url, true).query;
        const action = params["action"];
        const _keys = keys[action];
        if (_keys) {
            let command = __dirname + `/utils/system-server-scripts/${action}.sh`;
            for (const key of _keys) {
                const pair = key.split(" ");
                const getParam = param => ( params[param] || pair[1] );
                command += (key.substring(0, 1) === "-")
                    ? ` ${getParam(pair[0].substring(1))}` // do not quote
                    : ` '${getParam(pair[0])}'`;
            }
            exec(
                command,
                (error, stdout, stderr) => {
                    if (error) {
                        response.writeHead(500);
                        response.end();
                        console.error(`error: ${error.message}`);
                    } else if (stderr) {
                        response.writeHead(500);
                        response.end();
                        console.error(`stderr: ${stderr}`);
                    } else {
                        response.writeHead(200);
                        response.end(stdout);
                    }
                }
            );
        } else {
            response.writeHead(400);
            response.end();
            console.error(`unknown action: ${action}`);
        }
    })
    .listen(port);
