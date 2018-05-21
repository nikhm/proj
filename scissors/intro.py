import cv2
import numpy as np
from heapq import heappush, heappop

class CoordinateStore:
    def __init__(self, windowName, callbackIfPointsFound):
        self.points = []
        self.pointSet = set()
        self.window = windowName
        self.callback = callbackIfPointsFound

    def checkVicinity(self, point):
        x, y = point
        for i in range(-5,6):
            for j in range(-5,6):
                if (x+i, y+j) in self.pointSet:
                    return True
        return False

    def select_point(self, event, x, y, flags, param):
        if event == cv2.EVENT_LBUTTONDOWN:
            if( not self.checkVicinity((x,y)) ):
                self.points.append((x,y))
                self.pointSet.add((x,y))
                cv2.circle(img,(x,y), 1, (255,255,255), -1)
            else:
                cv2.setMouseCallback(self.window, lambda *args : None)
                self.callback(self.points)



# f(grayscaleImg, points) -> array of points connecting points (1)
# g( (1) ) -> image containing inside of (1)
# cost/similarity function(a,b) -> min(|a,b|+points between)
class Scissors:
    def __init__(self, img):
        self.img = img
        self.shape = img.shape
        self.numIterations = 0
        self.reset()

    def reset(self):
        self.points = []

    def distance(self, p, q):
        img = self.img
        shape = self.shape
        #print shape, p
        if ( (p[1] >= shape[0]) or (p[0] >= shape[1]) or (p[0] < 0) or (p[1] < 0)):
            return 100000
        if ( (q[1] >= shape[0]) or (q[0] >= shape[1]) or (q[0] < 0) or (q[1] < 0) ):
            return 100000
        return np.abs(img[q[1]][q[0]])
        #return np.abs(int(img[p[1]][p[0]]) - int(img[q[1]][q[0]]))

    # Gives distance from last q to p. also gives all points from p to q. (excluding p)
    def algo(self, p, q):
        img = self.img
        (x1, y1), (x2, y2) = p, q
        h = []
        dist, prev, visited = {}, {}, set()
        heappush(h, (0, (x1,y1)))
        dist[(x1,y1)] = 0
        while len(h):
            self.numIterations += 1
            (curDist, (x,y)) = heappop(h)
            if (x,y) == (x2,y2):
                break
            if (x, y) in visited:
                continue
            visited.add((x,y))
            for i in range(-1,2):
                for j in range(-1,2):
                    if (i == 0 and j == 0) or ((x+i,y+j) in visited) or (x+i < 0 or x+i >= img.shape[1]) or (y+j < 0 or y+j >= img.shape[1]):
                        continue
                    tmpDist = self.distance((x,y),(x+i,y+j)) + dist[(x,y)]
                    if ((x+i,y+j) not in dist) or (dist[(x+i,y+j)] > tmpDist):
                        dist[(x+i,y+j)] = tmpDist
                        prev[(x+i,y+j)] = (x,y)
                        heappush(h, (tmpDist, (x+i,y+j)))
        (a,b), orderedPoints = (x2,y2), []
        print (600*375)/self.numIterations
        while (a,b) != (x1,y1):
            orderedPoints.append((a,b))
            (a,b) = prev[(a,b)]
        orderedPoints.reverse()
        return (dist[q], orderedPoints)

    def work(self, arr):
        img = self.img
        l, allPoints = len(arr), [arr[0]]
        for i in range(1,l):
            _, points = self.algo(arr[i],arr[i-1])
            allPoints = allPoints + points
        return allPoints

def pointsFoundCallback(arr):
    scissors = Scissors(imgDisp)
    arr.append(arr[0])
    points = scissors.work(arr)
    l = len(points)
    for i in range(l):
        if (i/3)%2 == 0:
            img[points[i][1]][points[i][0]] = 255
    print 'Done!'

img = cv2.imread('a.jpg')
img = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)

imgDisp = cv2.Canny(img,100,200)
imgDisp = (np.amax(imgDisp) - imgDisp)/255
imgDisp = 4*imgDisp + 1

cv2.namedWindow('image')
coordinateStore = CoordinateStore('image',pointsFoundCallback);
cv2.setMouseCallback('image', coordinateStore.select_point)

while(1):
    cv2.imshow('image', img)
    #cv2.imshow('diff',imgDisp)
    k = cv2.waitKey(27) and 0xFF
    if k == 27:
        break

cv2.destroyAllWindows()
