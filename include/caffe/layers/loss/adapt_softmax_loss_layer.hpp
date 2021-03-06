#ifndef CAFFE_ADAPT_SOFTMAX_WITH_LOSS_LAYER_HPP_
#define CAFFE_ADAPT_SOFTMAX_WITH_LOSS_LAYER_HPP_

#include <vector>

#include "caffe/blob.hpp"
#include "caffe/layer.hpp"
#include "caffe/proto/caffe.pb.h"

#include "caffe/layers/activation/softmax_layer.hpp"

namespace caffe {

template <typename Dtype>
class AdaptSoftmaxWithLossLayer : public Layer<Dtype> 
{
 public:
  explicit AdaptSoftmaxWithLossLayer(const LayerParameter& param) : Layer<Dtype>(param) {}
  virtual inline const char* type() const { return "AdaptSoftmaxWithLoss"; }
  
  
  virtual void LayerSetUp(const vector<Blob<Dtype>*>& bottom, const vector<Blob<Dtype>*>& top);
  virtual void Reshape(const vector<Blob<Dtype>*>& bottom, const vector<Blob<Dtype>*>& top);

  virtual void Forward_gpu(const vector<Blob<Dtype>*>& bottom, const vector<Blob<Dtype>*>& top);
 

  virtual void Backward_gpu(const vector<Blob<Dtype>*>& top, const vector<Blob<Dtype>*>& bottom);
  virtual void SecForward_gpu(const vector<Blob<Dtype>*>& bottom, const vector<Blob<Dtype>*>& top);

 protected:
  



  Blob<Dtype> prob_;
  
  Blob<Dtype> temp_prob;
  
  shared_ptr<Layer<Dtype> > softmax_layer_;
 
  
  Blob<Dtype> flag;
  vector<Blob<Dtype>*> softmax_bottom_vec_;
  vector<Blob<Dtype>*> softmax_top_vec_;

  bool has_ignore_label_;
 
  int ignore_label_;
 
  Blob<Dtype> counts_;
  Blob<Dtype> sub_counts_;
  Blob<Dtype> loss_;
 	Dtype portion;
 

};

}  // namespace caffe

#endif  // CAFFE_Adapt_SOFTMAX_WITH_LOSS_LAYER_HPP_
