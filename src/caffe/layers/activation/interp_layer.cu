#include <vector>

#include "caffe/layers/activation/interp_layer.hpp"
#include "caffe/util/math_functions.hpp"

namespace caffe {

template <typename Dtype>
static __global__ void interp_foward_kernel(int IND,int channels,int height_in,int width_in,int height_out,int width_out,const Dtype * id, Dtype *od)
{
	CUDA_KERNEL_LOOP(ind, IND)
  {
  	int w=ind % width_out;
  	int h=ind / width_out % height_out;
  	int c=ind / width_out / height_out % channels;
  	int n=ind / width_out / height_out / channels;
  	
  	int h_in = floor(Dtype(h)/Dtype(height_out)*Dtype(height_in));
  	int w_in = floor(Dtype(w)/Dtype(width_out)*Dtype(width_in));
  	int ind_in = 	((n*channels+c)*height_in + h_in)*width_in + w_in;
  	od[ind] = id[ind_in];
  }
}

template <typename Dtype>
static __global__ void interp_backward_0_kernel(int IND,int channels,int height_in,int width_in,int height_out,int width_out,const Dtype * id, Dtype *od)
{
	CUDA_KERNEL_LOOP(ind, IND)
  {
  	int w=ind % width_out;
  	int h=ind / width_out % height_out;
  	int c=ind / width_out / height_out % channels;
  	int n=ind / width_out / height_out / channels;
  	
  	int h_in = floor(Dtype(h)/Dtype(height_out)*Dtype(height_in));
  	int w_in = floor(Dtype(w)/Dtype(width_out)*Dtype(width_in));
  	int ind_in = 	((n*channels+c)*height_in + h_in)*width_in + w_in;
  	od[ind_in] = id[ind];
  }
}

template <typename Dtype>
static __global__ void interp_backward_1_kernel(int IND,int channels,int height_out,int width_out,int height_in,int width_in,const Dtype * od, Dtype *id)
{
	CUDA_KERNEL_LOOP(ind, IND)
  {
  	int w=ind % width_in;
  	int h=ind / width_in % height_in;
  	int c=ind / width_in / height_in % channels;
  	int n=ind / width_in / height_in / channels;
  	
  	int h_begin = ceil(Dtype(h)/Dtype(height_in)*Dtype(height_out));
  	int h_end = ceil(Dtype(h+1)/Dtype(height_in)*Dtype(height_out));
  	int w_begin = ceil(Dtype(w)/Dtype(width_in)*Dtype(width_out));
  	int w_end = ceil(Dtype(w+1)/Dtype(width_in)*Dtype(width_out));
  	
  	Dtype sum = 0;
  	for(int h_out=h_begin;h_out<h_end;h_out++)
  	for(int w_out=w_begin;w_out<w_end;w_out++)
  	{
  		int ind_out = ((n*channels+c)*height_out + h_out)*width_out + w_out;
  		sum += od[ind_out];
  	} 	
  	id[ind] = sum;
  }
}

template <typename Dtype>
void InterpLayer<Dtype>::Forward_gpu(const vector<Blob<Dtype>*>& bottom, const vector<Blob<Dtype>*>& top) 
{
	interp_foward_kernel<Dtype><<<CAFFE_GET_BLOCKS(top[0]->count()), CAFFE_CUDA_NUM_THREADS>>>
	(top[0]->count(),top[0]->channels(),bottom[0]->height(),bottom[0]->width(),top[0]->height(),top[0]->width(),
		bottom[0]->gpu_data(),top[0]->mutable_gpu_data());			                                        
}

template <typename Dtype>
void InterpLayer<Dtype>::Backward_gpu(const vector<Blob<Dtype>*>& top, const vector<Blob<Dtype>*>& bottom) 
{
	if (bottom[0]->height() > top[0]->height())
	{
		caffe_gpu_set(bottom[0]->count(),Dtype(0),bottom[0]->mutable_gpu_diff());
		interp_backward_0_kernel<Dtype><<<CAFFE_GET_BLOCKS(top[0]->count()), CAFFE_CUDA_NUM_THREADS>>>
		(top[0]->count(),top[0]->channels(),bottom[0]->height(),bottom[0]->width(),top[0]->height(),top[0]->width(),
				top[0]->gpu_diff(),bottom[0]->mutable_gpu_diff());						
	}
	else
	{
		interp_backward_1_kernel<Dtype><<<CAFFE_GET_BLOCKS(bottom[0]->count()), CAFFE_CUDA_NUM_THREADS>>>
		(bottom[0]->count(),bottom[0]->channels(),top[0]->height(),top[0]->width(),bottom[0]->height(),bottom[0]->width(),
				top[0]->gpu_diff(),bottom[0]->mutable_gpu_diff());	
	}		 
	
}
template <typename Dtype>
void InterpLayer<Dtype>::SecForward_gpu(const vector<Blob<Dtype>*>& bottom, const vector<Blob<Dtype>*>& top) 
{
	
	interp_foward_kernel<Dtype><<<CAFFE_GET_BLOCKS(top[0]->count()), CAFFE_CUDA_NUM_THREADS>>>
	(top[0]->count(),top[0]->channels(),bottom[0]->height(),bottom[0]->width(),top[0]->height(),top[0]->width(),
		bottom[0]->gpu_sec_diff(),top[0]->mutable_gpu_sec_diff());		                                            
}

INSTANTIATE_LAYER_GPU_FUNCS(InterpLayer);
}  // namespace caffe
