This folder is for blocked bloom filter implementation, everything is same as bloom filter, 
except it uses multi bit vectors with size 512 bits instead of a single bit vector to record the hash values.

**PLEASE note that if bit vector size is lower than 512, please run bloom filter implementation instead, this implementation is not for small N.

##This folder contains the implementation of Blocked Bloom Filter(`BlockBF.cpp`, `BlockBF.h` and `BloomFilter.h`). 
- To run Bloom Filter, please run `g++ blockBF.cpp -o bf` with g++ installed\
  1. There are two main functions in this implementation, which are `build` and `query`
  - To run build function, please run  
  ```
  $bf build -k <key file> -f <fpr> -n <num. distinct keys> -o <output file>
  ``` 
  please provide a `<key file>`, which contains `<num. distinct keys>` distinct input keys, 
  and construct a bloom filter with a target false positive rate of `<fpr>`. The constructed Bloom filter should be written to the file `<output file>`.
For example, please run 'build -k list.txt -f 0.001 -n 10 -o out.txt'

  - To run query function, please run  
```
$bf query -i <input file> -q <queries> -o <output file>
```


  please provide a `<input file>`, which contains the <output file> from `build`, and a <queries>, which has a query in each line. 
  Please also provide a output file <output file> for writing down the result of queries.
  For example, please run 'query -i out.txt -q list.txt -o queryResults.txt'


`R_test` folder is used for testing the performance, Please run  `Rscript R_test.r`. It will return three plots:
- Key Size Vs Runtime
- Ture FPR Vs Empirical FPR for Queries which are not inserted.
- Ture FPR Vs Empirical FPR  for Queries that half of them are not inserted.

