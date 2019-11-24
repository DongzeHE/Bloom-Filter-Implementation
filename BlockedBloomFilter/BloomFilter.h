// This is the head file of assignment 2.
#include "pch.h"
#include <array>
#include <vector>
#include <string>
#include <list>
#include <iostream>
#include <sstream>
#include <fstream>
#include <cstdlib>
#include <cmath>
#include "smhasher-master/src/MurmurHash3.h"
#include "smhasher-master/src/MurmurHash3.cpp"
using namespace std;


class bf {
public:
    bf(int bvSize, int NumofHash);
    int bvSize;
    void insert( string keyValue);
    bool query( string keyValue);
    void printBV();
    void updateBV(std::vector<bool> BV);
    void writeOutput(string outFile_path);

    int numHashes;
    vector<bool> bv;
};



// two private vars for bloomfilter, bv and num of hashes
bf::bf(int bvSize, int NumofHash):
        bv(bvSize),
        bvSize(bvSize),
        numHashes(NumofHash){}

void bf::printBV(){
    int bvSize = bv.size();
    for (int i = 0; i < bvSize; i++) {
        std::cout << bv.at(i) << ' ';
    }
    cout << endl;
}

void bf::updateBV(std::vector<bool> BV)
{
    bv = BV;
}

void bf::writeOutput(string outFile_path)
{
    ofstream outfile(outFile_path, ios::out | ios::trunc | ios::binary);
    outfile << bvSize;
    outfile << "\n";
    outfile << numHashes;
    outfile << "\n";
    std::ostream_iterator<bool> output_iterator(outfile);
    std::copy(bv.begin(), bv.end(), output_iterator);
    outfile.close();

}

bf  bf::readBVfile(string inFile_path)
{
    int M;
    int k;
    ifstream inFile(inFile_path);
    inFile >> M;
    inFile >> k;
    string BV_str;
    vector<bool> BV;
    inFile >> BV_str;
    inFile.close();
//    cout <<endl<< "Here is the query result: \n";

    for ( int i = 0 ; i < BV_str.length(); i++) {
        BV.push_back(BV_str[i] == '1');
    }
    bf BloomFilter(M, k);
    BloomFilter.updateBV(BV);
    return BloomFilter;
}

// Using Murmurhash function to hash, which will return two parts
array<uint64_t, 2> mmh( string keyValue) {
    // define input and output for mmh
    //output:
    array<uint64_t, 2> hashValue;

    //input:
    size_t keyLen = keyValue.length() + 1;
    string *keyptr = &keyValue;

    //cout << keyValue << endl;
    //cout << keyLen << endl;

    // Hash it!
    MurmurHash3_x64_128(keyptr, keyLen, 0, hashValue.data());

    // return hashvalue array, which has 2 uint64_t.
    return hashValue;
}

// build a iterable hash function
inline uint64_t ithHash(uint8_t i,
                        uint64_t mmhA,
                        uint64_t mmhB,
                        uint64_t bvSize) {

//    std::cout << endl << (mmhA + i * mmhB) % bvSize << endl;
    return (mmhA + i * mmhB) % bvSize;
}

// Insert function
void bf::insert(string keyValue) {

    // Hash it!
    array<uint64_t, 2> hashValues = mmh(keyValue);

    //Update bv
    for (int i = 0; i < numHashes; i++) {
//        std::cout << "The " << i << "-th hash values are:" << endl;
        bv[ithHash(i, hashValues[0], hashValues[1], bv.size())] = true;
    }
}

// query function
bool bf::query(string keyValue)  {

    //Hash it!
    array<uint64_t, 2> hashValues = mmh(keyValue);

    //query the hashvalues
    for (int i = 0; i < numHashes; i++) {
        if (!bv[ithHash(i, hashValues[0], hashValues[1], bv.size())]) {
            return false;
        }
    }
    return true;
}
