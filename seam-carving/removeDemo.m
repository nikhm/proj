clc; clear all; close all;

img = (imread('a1.jpg'));
dimg = deleteObject(img);
figure, imshow(dimg);