import subprocess, random, time

def getActiveWorkers():
    out = subprocess.check_output("kubectl get pods | grep corekube-worker | grep Running | awk -F ' ' '{ print $1 }'", shell=True).decode("utf-8")
    if out == "":
        return []
    return out.strip().split("\n")

def killRandomWorker():
    workers = getActiveWorkers()
    if len(workers) == 0:
        return
    killWorker = random.choice(workers)
    logTime = time.strftime("%Y-%m-%d_%H-%M-%S")
    with open("kill_list.txt", "a") as kl:
        kl.write("%s %s\n" % (logTime, killWorker))
    subprocess.call("kubectl delete pod %s" % killWorker, shell=True)

while True:
    killRandomWorker()
    time.sleep(60)