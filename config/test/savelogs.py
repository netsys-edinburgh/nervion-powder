#!/usr/bin/python3

import os, subprocess, signal, time, json


ORIGINAL_LOG_DIR="/var/log/containers"
OUTPUT_LOG_DIR=os.path.expanduser("~/newlogs")
LOG_FILE=os.path.expanduser("~/log_for_savelogs.log")


def checkFolders():
    if not os.path.isdir(ORIGINAL_LOG_DIR):
        failMsg = "Original log dir: %s not a directory" % ORIGINAL_LOG_DIR
        log(failMsg)
        raise Exception(failMsg)
    if not os.path.isdir(OUTPUT_LOG_DIR):
        os.mkdir(OUTPUT_LOG_DIR)


def log(msg):
    logTime = time.strftime("%Y-%m-%d_%H-%M-%S")
    logMsg = "%s %s" % (logTime, msg)
    with open(LOG_FILE, "a") as lf:
        lf.write(logMsg + "\n")
    print(logMsg)


def getLogFiles():
    logFiles = [file for file in os.listdir(ORIGINAL_LOG_DIR) if file.endswith(".log")]
    return logFiles


def getRunningLogFiles():
    logFiles = [file for file in os.listdir(OUTPUT_LOG_DIR) if file.endswith(".log")]
    return logFiles


def getNewLogFiles():
    newLogFiles = [logFile for logFile in getLogFiles() if logFile not in getRunningLogFiles()]
    return newLogFiles


def logNewFiles():
    newLogFiles = getNewLogFiles()
    for newLogFile in newLogFiles:
        log("Starting new log file: %s" % newLogFile)
        cmd = "sudo tail --follow=name -n +1 %s/%s > %s/%s" % (ORIGINAL_LOG_DIR, newLogFile, OUTPUT_LOG_DIR, newLogFile)
        pro = subprocess.Popen(cmd, stdout=subprocess.PIPE, shell=True)


if __name__ == "__main__":
    checkFolders()
    logNewFiles()
