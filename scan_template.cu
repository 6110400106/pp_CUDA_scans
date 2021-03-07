#include<stdio.h>
#include<math.h>

#define N 8

__global__ void exclusive_scan(int *d_in) {
	
	__shared__ int temp_in[N];

	int id = threadIdx.x;
        temp_in[id] = d_in[id];
        __syncthreads();

	unsigned int s = 1;
        for(; s <= N-1; s <<= 1) {
                int i = 2 * s * (threadIdx.x + 1) - 1;
		if(i >= s && i < N){
                        //printf("s = %d, i = %d \n", s, i);
                        int a = temp_in[i];
                        int b = temp_in[i-s];
                        __syncthreads();
                        temp_in[i] = a + b;
                }
                __syncthreads();
        }
	
	if(threadIdx.x == 0) {
                temp_in[N-1] = 0;
        }
        for(s = s/2; s >= 1; s >>= 1) {
                int i = 2*s*(threadIdx.x+1)-1;
                if(i >= s && i < N){
                        //printf("s = %d, i = %d \n", s, i);
                        int r = temp_in[i];
                        int l = temp_in[i-s];
                        __syncthreads();
                        temp_in[i] = l + r;
                        temp_in[i-s] = r;
                }
                __syncthreads();
        }
	d_in[id] = temp_in[id];

	//Teacher's code
	/*
	//Phase 1 Uptree
	int s = 1;
	for(; s <= N-1; s <<= 1) {
		int i = 2 * s * (threadIdx.x + 1) - 1;
		if(i-s >= 0 && i < N){
			//printf("s = %d, i = %d \n", s, i);
			int a = d_in[i];
			int b = d_in[i-s];
			__syncthreads();
			d_in[i] = a + b;
		}
		__syncthreads();
	}


	//Phase 2 Downtree
	if(threadIdx.x == 0) {
		d_in[N-1] = 0;
	}
	for(s = s/2; s >= 1; s >>= 1) {
		int i = 2*s*(threadIdx.x+1)-1;
		if(i-s >= 0 && i < N){
                        //printf("s = %d, i = %d \n", s, i);
                        int r = d_in[i];
                        int l = d_in[i-s];
                        __syncthreads();
                        d_in[i] = l + r;
			d_in[i-s] = r;
                }
                __syncthreads();
	}
	*/
}

__global__ void inclusive_scan(int *d_in) {
	
	__shared__ int temp_in[N];

	int i = threadIdx.x;
	temp_in[i] = d_in[i];

	__syncthreads();

	for(unsigned int s = 1; s <= N-1; s <<= 1) {
		if(i >= s && i < N) {
			int a = temp_in[i];
			int b = temp_in[i-s];
			int c = a + b;
			temp_in[i] = c;
		}	
		__syncthreads();
	}

	d_in[i] = temp_in[i];

}

int main()
{
	int h_in[N] = {3, 1, 7, 0, 4, 1, 6, 3};
	int h_out[N];

	//for(int i=0; i < N; i++)
	//	h_in[i] = 1;
	
	cudaEvent_t start, stop;
	cudaEventCreate(&start);
	cudaEventCreate(&stop);

	int *d_in;
	//int *d_out;

	cudaMalloc((void**) &d_in, N*sizeof(int));
	//cudaMalloc((void**) &d_out, N*sizeof(int));
	cudaMemcpy(d_in, &h_in, N*sizeof(int), cudaMemcpyHostToDevice);
	
	//Implementing kernel call
	//Timed each kernel call
	cudaEventRecord(start);
	//inclusive_scan<<<1, N>>>(d_in);
	exclusive_scan<<<1, N>>>(d_in);
	cudaEventRecord(stop);


	cudaMemcpy(&h_out, d_in, N*sizeof(int), cudaMemcpyDeviceToHost);
	
	cudaEventSynchronize(stop);
	float milliseconds = 0;
	cudaEventElapsedTime(&milliseconds, start, stop);
	
	cudaFree(d_in);
	//cudaFree(d_out);

	for(int i=0; i<N; i++)
		printf("out[%d] =  %d\n", i, h_out[i]); 
	printf("Time used: %f milliseconds\n", milliseconds);

	return -1;

}
