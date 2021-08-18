import subprocess, time

ENB = "slave-2"
masterAddress = "pcvm604-1.emulab.net"

while True:
    try:
        out = subprocess.check_output(f"kubectl logs {ENB} | grep ERROR", shell=True).decode("utf-8")
        subprocess.call(f"curl http://{masterAddress}:34567/restart/", shell=True)
        raise Exception()
    except subprocess.CalledProcessError:
        time.sleep(10)
