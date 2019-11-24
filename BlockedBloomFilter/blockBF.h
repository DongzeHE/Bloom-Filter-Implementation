// This is the head file of assignment 2.
#include <array>
#include <vector>
#include <string>
#include <list>
#include <iostream>
#include <sstream>
#include <fstream>
#include <cstdlib>
#include <cmath>
using namespace std;


class blockBF {
public:
    blockBF(int bvSize, int NumofHash);
    int NumofBV;
    void printBV();
    void insert( string keyValue);
    bool query( string keyValue);
    void writeOutput(string outFile_path);
    void updateBV(vector<vector<bool> > BV);
    int k;
    vector<vector<bool> > bv;
};
