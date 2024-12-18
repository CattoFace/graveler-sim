#include "kernel.cu"
#include <curand_kernel.h>
#include <iostream>

#define BLOCKSIZE 1024
int main() {
  int *d_grid_max;
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
  cudaMallocManaged(&d_grid_max, block_count * sizeof(int));
  int black_box = 0; // to prevent optimizing away the entire loop
  int global_max;
  // warm-up
  for (int i = 0; i < 50; i++) {
    rng<<<block_count, BLOCKSIZE, 0>>>(d_grid_max, time(nullptr));
    cudaDeviceSynchronize();
    global_max = d_grid_max[0];
    for (int i = 1; i < block_count; i++) {
      global_max = max(global_max, d_grid_max[i]);
    }
    black_box += global_max;
  }
  cudaEventRecord(start);
  for (int i = 0; i < 1000; i++) {
    rng<<<block_count, BLOCKSIZE, 0>>>(d_grid_max, time(nullptr));
    cudaDeviceSynchronize();
    global_max = d_grid_max[0];
    for (int i = 1; i < block_count; i++) {
      global_max = max(global_max, d_grid_max[i]);
    }
    black_box += global_max;
  }
  cudaEventRecord(stop);
  cudaEventSynchronize(stop);
  float t = 2;
  std::cout << "Max: " << global_max << '\n';
  cudaEventElapsedTime(&t, start, stop);
  std::cout << "avg of 100 runs " << t / 1000 << "ms\n";
  cudaFree(d_grid_max);
  std::cout << black_box << "\n";
  return 0;
}
