#include "kernel.cu"
#include <curand_kernel.h>
#include <iostream>

#define BLOCKSIZE 1024
int main() {
  unsigned char *d_grid_max;
  int deviceId;
  cudaDeviceProp prop;
  cudaEvent_t start, stop;
  cudaEventCreate(&start);
  cudaEventCreate(&stop);
  cudaGetDevice(&deviceId);
  cudaGetDeviceProperties(&prop, deviceId);
  int sm_count = prop.multiProcessorCount;
  int block_per_sm = 0;
  cudaOccupancyMaxActiveBlocksPerMultiprocessor(&block_per_sm, rng, BLOCKSIZE,
                                                0);
  int block_count = sm_count * block_per_sm;
  cudaMallocManaged(&d_grid_max, block_count);
  // warm-up
  for (int i = 0; i < 10; i++) {
    rng<<<block_count, BLOCKSIZE>>>(d_grid_max, time(nullptr));
    cudaDeviceSynchronize();
  }
  cudaEventRecord(start, nullptr);
  for (int i = 0; i < 10; i++) {
    rng<<<block_count, BLOCKSIZE>>>(d_grid_max, time(nullptr));
    cudaDeviceSynchronize();
  }
  cudaEventRecord(stop, nullptr);
  float t = 0;
  int global_max = d_grid_max[0];
  for (int i = 1; i < block_count; i++) {
    global_max = max(global_max, d_grid_max[i]);
  }
  cudaEventElapsedTime(&t, start, stop);
  std::cout << "average of 10 runs " << t / 10 << "ms\n";
  std::cout << "Max: " << global_max << '\n';
  cudaFree(d_grid_max);
  return 0;
}
