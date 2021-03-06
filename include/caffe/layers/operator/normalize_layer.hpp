#ifndef CAFFE_NORMALIZATION_LAYER_HPP_
#define CAFFE_NORMALIZATION_LAYER_HPP_

#include <vector>

#include "caffe/blob.hpp"
#include "caffe/layer.hpp"
#include "caffe/filler.hpp"
#include "caffe/proto/caffe.pb.h"

namespace caffe {

template <typename Dtype>
class NormalizeLayer : public Layer<Dtype> 
{
 public:
  explicit NormalizeLayer(const LayerParameter& param): Layer<Dtype>(param) {}
  virtual inline const char* type() const { return "Normalize"; }
  
  virtual void LayerSetUp(const vector<Blob<Dtype>*>& bottom,  const vector<Blob<Dtype>*>& top);
  virtual void Reshape(const vector<Blob<Dtype>*>& bottom,     const vector<Blob<Dtype>*>& top);

  virtual void Forward_gpu(const vector<Blob<Dtype>*>& bottom, const vector<Blob<Dtype>*>& top);

  virtual void Backward_gpu(const vector<Blob<Dtype>*>& top,   const vector<Blob<Dtype>*>& bottom);
	virtual void SecForward_gpu(const vector<Blob<Dtype>*>& bottom, const vector<Blob<Dtype>*>& top);
 protected:


  Blob<Dtype> norm_;
  Blob<Dtype> sum_channel_multiplier_, sum_spatial_multiplier_;
  Blob<Dtype> buffer_, buffer_channel_, buffer_spatial_;
  Dtype eps_;
};

}  // namespace caffe

#endif  // CAFFE_BATCHNORM_LAYER_HPP_
