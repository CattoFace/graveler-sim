#include "kernel.cu"
#include <iostream>

#define BLOCKSIZE 1024
int main() {
  int *d_grid_max;
  int deviceId;
  cudaDeviceProp prop;
  cudaEvent_t start, stop;
  cudaEventCreate(&start);
  cudaEventCreate(&stop);
  cudaEventRecord(start);
  cudaGetDevice(&deviceId);
  cudaGetDeviceProperties(&prop, deviceId);
  int sm_count = prop.multiProcessorCount;
  int block_per_sm = 0;
  cudaOccupancyMaxActiveBlocksPerMultiprocessor(&block_per_sm, rng, BLOCKSIZE,
                                                0);
  int block_count = sm_count * block_per_sm;
  cudaMallocManaged(&d_grid_max, block_count * sizeof(int));
  rng<<<block_count, BLOCKSIZE>>>(d_grid_max, 42);
  cudaDeviceSynchronize();
  float t = 0;
  int global_max = d_grid_max[0];
  for (int i = 1; i < block_count; i++) {
    global_max = max(global_max, d_grid_max[i]);
  }
  cudaEventRecord(stop);
  cudaEventSynchronize(stop);
  std::cout << "Max: " << global_max << '\n';
  cudaEventElapsedTime(&t, start, stop);
  std::cout << "kernel ran in " << t << "\n";
  cudaFree(d_grid_max);
  return 0;
}
