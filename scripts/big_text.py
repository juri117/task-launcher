
import time

if __name__ == '__main__':
    i = 0
    while True:
        print("test test test test test test test test test test test test test test test test {:09d}".format(i), flush=True)
        i+=1
        time.sleep(0.1)