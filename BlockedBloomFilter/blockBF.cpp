// This is the main function of assignment 2.
#include "blockBF.h"
#include "MurmurHash3.cpp"
#define LOG(x) std::cout<< std::endl << "LOG: "<< x << std::endl<< std::endl;

using namespace std;

// two private vars for bloomfilter, bv and num of hashes
blockBF::blockBF(int NumBV, int NumofHash):
        k(NumofHash),
        NumofBV(NumBV){
    for (int i = 0; i < NumBV ; ++i) {
        vector<bool> tempBV(512);
        bv.push_back(tempBV);
    }
}

void blockBF::printBV(){
    for (int j = 0; j < NumofBV; ++j) {
        int bvSize = bv[j].size();
        for (int i = 0; i < bvSize; i++) {
            std::cout << bv[j].at(i) << ' ';
        }
        cout << endl;
    }
}

// Using Murmurhash function to hash, which will return two parts
array<uint64_t, 2> mmh(string keyValue) {
    // define input and output for mmh
    //output:
    array<uint64_t, 2> hashValue;

    //input:
    size_t keyLen = keyValue.length()+1;
    const string *keyptr = &keyValue;

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

    return (mmhA + i * mmhB) % bvSize;
}

// Insert function
void blockBF::insert(string keyValue) {
    // Hash it!
    array<uint64_t, 2> hashValues = mmh(keyValue);
    int which_bv = ithHash(0, hashValues[0], hashValues[1], NumofBV);

    //Update bv
    for (int i = 1; i <= k; i++) {
        bv[which_bv][ithHash(i, hashValues[0], hashValues[1], 512)] = true;
    }
}


// query function
bool blockBF::query(string keyValue)  {

    //Hash it!
    array<uint64_t, 2> hashValues = mmh(keyValue);
    int which_bv = ithHash(0, hashValues[0], hashValues[1], NumofBV);

    //query the hashvalues
    for (int i = 1; i <= k; i++) {
        if (!bv[which_bv][ithHash(i, hashValues[0], hashValues[1], 512)]) {
            return false;
        }
    }
    return true;
}

// Write output for further analysis
void blockBF::writeOutput(string outFile_path)
{
    ofstream outfile(outFile_path, ios::out | ios::trunc | ios::binary);
    outfile << NumofBV;

    outfile << "\n";
    outfile << k;
    outfile << "\n";
    std::ostream_iterator<bool> output_iterator(outfile);

    for (int i = 0; i < NumofBV; ++i) {
        std::copy(bv[i].begin(), bv[i].end(), output_iterator);
        outfile << "\n";
    }
    outfile.close();
}



void blockBF::updateBV(vector<vector<bool> > BV)
{
    bv = BV;
}

blockBF  readBVfile(string inFile_path)
{
    int NumofBV;
    int k;
    ifstream inFile(inFile_path);
    inFile >> NumofBV;
    inFile >> k;
    string BV_str;
    vector<vector<bool> > BV;
    while (inFile.good()) {
        inFile >> BV_str;
        vector<bool> tempBV;
        for ( int i = 0 ; i < BV_str.length(); i++) {
            tempBV.push_back(BV_str[i] == '1');
        }
        BV.push_back(tempBV);
    }

    inFile.close();
    blockBF BloomFilter(NumofBV, k);
    BloomFilter.updateBV(BV);
    return BloomFilter;
}





//-----------------------------------------------------------------------------


int main(int argc, char* argv[]) {
    // if has only one file name, output the descriptions.
    int N;
    int M;
    int k;
    int NumofBV;
    float FPR;
    string key_file;
    string bv_file;
    string outFile_path;
    string fun_apply;
    ifstream inFile;
    ofstream outFile;

    if (argc == 1) {
        std::cout << "This program is used for building bloom filter from a given input string file. \n-k <key file> \n-f <fpr> \n-n <num. distinct keys> \n-o <output file>";
        return 0;
    }

        // Read in args
    else {
        // First argument is the function want to use.
        fun_apply = argv[1];

        if (fun_apply == "build")
        {
            // -k <key file> -f <fpr> -n <num. distinct keys> -o <output file>
            for (int i = 2; i < argc; i += 2) {
                // Define the arg for this iteration.
                string arg_type = argv[i];

                // Read in the arg of this iteration.
                string arg = argv[i + 1];

                if (arg_type == "-k") {
                    //Frist identity -k

                    stringstream key_file_str(arg);
                    key_file_str >> key_file;
                }
                else if (arg_type == "-f") {
                    //Then identify -f
                    stringstream FPR_str(arg);
                    FPR_str >> FPR;
                }
                    //Then identify -n
                else if (arg_type == "-n") {
                    stringstream N_str(arg);
                    N_str >> N;
                }
                    // Finally identify -o
                else if (arg_type == "-o") {
                    stringstream outFile_str(arg);
                    outFile_str >> outFile_path;
                }
            }

            //build -k list.txt -f 0.001 -n 10 -o out.txt

            M = ceil(-((N*log(FPR)) / pow(log(2), 2.0)));
            k = ceil((M / N) * log(2));
            NumofBV = ceil(float(M)/512);
            blockBF BloomFilter(NumofBV, k);

            inFile.open(key_file);
            if (!inFile.is_open()) {
                exit(EXIT_FAILURE);
            }

            string word;
            inFile >> word;
            while (inFile.good()) {
                BloomFilter.insert(word);
                inFile >> word;
            }
            std::cout << "Number of BV = " << BloomFilter.NumofBV << "\nk = " << k << "\n";
            BloomFilter.writeOutput(outFile_path);
        }

        else {

            // Building up query function
            // query -i out.txt -q list.txt -o queryResults.txt
            for (int i = 2; i < argc; i += 2) {
                // Define the arg for this iteration.
                string arg_type = argv[i];

                // Read in the arg of this iteration.
                string arg = argv[i + 1];

                if (arg_type == "-i") {
                    //First identity -k

                    stringstream bv_file_str(arg);
                    bv_file_str >> bv_file;
                }
                else if (arg_type == "-q") {
                    //Then identity -q

                    stringstream key_file_str(arg);
                    key_file_str >> key_file;
                }
                else if (arg_type == "-o") {
                    //Then identity -o

                    stringstream out_file_str(arg);
                    out_file_str >> outFile_path;
                }
            }

            blockBF BloomFilter = readBVfile(bv_file);

                      ofstream queryFile(outFile_path, ios::out | ios::trunc | ios::binary);

                      inFile.open(key_file);
                      string key;
                      inFile >> key;
                      while (inFile.good()) {
                          bool query_result = BloomFilter.query(key);

                          if(query_result){
                              queryFile << key;
                              queryFile << "\t";
                              queryFile << 1;
                              queryFile << "\n";
                          }else{
                              queryFile << key;
                              queryFile << "\t";
                              queryFile << 0;
                              queryFile << "\n";
                          }

                          inFile >> key;
                      }

                      queryFile.close();


        }

    }
    return 0;

}
