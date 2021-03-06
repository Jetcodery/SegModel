#include <vector>

#include "caffe/layer.hpp"
#include "caffe/layers/operator/conv_layer.hpp"
#include "caffe/util/im2col.hpp"
#include "caffe/util/math_functions.hpp"

namespace caffe {

template <typename Dtype>
void ConvolutionLayer<Dtype>::Forward_gpu(const vector<Blob<Dtype>*>& bottom, const vector<Blob<Dtype>*> &top) 
{
  const Dtype* bottom_data = bottom[0]->gpu_data();
  Dtype* top_data = top[0]->mutable_gpu_data();
  Dtype* col_data = col_buffer_->mutable_gpu_data();
  const Dtype* weight = this->blobs_[0]->gpu_data();
  
  int num = bottom[0]->num();
  int channels = bottom[0]->channels();
  int height = bottom[0]->height();
  int width = bottom[0]->width();
 
 	int top_offset_ = height_out_ * width_out_ * num_output_ / group_;
 	int col_offset_ = height_out_ * width_out_ * kernel_size_ * kernel_size_ * channels / group_;
 	int weight_offset_ = kernel_size_ * kernel_size_ * channels * num_output_ / group_ / group_;

  for (int n = 0; n < num; ++n) 
  {
    im2col_gpu(bottom_data + bottom[0]->offset(n), channels, height,width, 
    kernel_size_, kernel_size_, pad_, pad_, stride_, stride_, filter_stride_, filter_stride_, 
    col_data);   
    
    for (int g = 0; g < group_; g++) 
  	{
		  caffe_gpu_gemm<Dtype>(CblasNoTrans, CblasNoTrans, num_output_/ group_, height_out_*width_out_, kernel_size_*kernel_size_*channels/ group_,
														(Dtype)1., weight+ weight_offset_ * g , col_data + col_offset_ * g,
														(Dtype)0., top_data + top[0]->offset(n) + top_offset_ * g );  
		}												
    if (this->layer_param_.convolution_param().bias_term()) 
    {
      caffe_gpu_gemm<Dtype>(CblasNoTrans, CblasNoTrans, num_output_,height_out_*width_out_, 1, 
														(Dtype)1., this->blobs_[1]->gpu_data(), bias_multiplier_->gpu_data(),
														(Dtype)1., top_data + top[0]->offset(n));
    }    
  }     
}

template <typename Dtype>
void ConvolutionLayer<Dtype>::Backward_gpu(const vector<Blob<Dtype>*>& top, const vector<Blob<Dtype>*>& bottom) 
{	
	int num = bottom[0]->num();
  int channels = bottom[0]->channels();
  int height = bottom[0]->height();
  int width = bottom[0]->width();
  
//---------------------------------------------------------------------------------------------------
	col_buffer_->Reshape(kernel_size_*kernel_size_*channels,height_out_*width_out_,1,1);
	if (this->layer_param_.convolution_param().bias_term())
  {
    bias_multiplier_->Reshape(1,1,height_out_,width_out_);   
    caffe_gpu_set(bias_multiplier_->count(),Dtype(1),bias_multiplier_->mutable_gpu_data()); 
  }
//---------------------------------------------------------------------------------------------------

  const Dtype* top_diff = top[0]->gpu_diff();
  const Dtype* weight = this->blobs_[0]->gpu_data();
  const Dtype* bottom_data = bottom[0]->gpu_data();
  
  Dtype* bottom_diff = bottom[0]->mutable_gpu_diff();
  Dtype* weight_diff = this->blobs_[0]->mutable_gpu_diff();
  Dtype* col_data = col_buffer_->mutable_gpu_data();
  Dtype* col_diff = col_buffer_->mutable_gpu_diff();


  if (this->layer_param_.convolution_param().bias_term() && this->lr_mult()[1] > 0 && Caffe::frozen_param() == false) 
  {
		Dtype* bias_diff = this->blobs_[1]->mutable_gpu_diff();
		for (int n = 0; n < num; ++n)  
		{
			caffe_gpu_gemv<Dtype>(CblasNoTrans, num_output_, height_out_ * width_out_, 
		  			(Dtype)1., top_diff + top[0]->offset(n), bias_multiplier_->gpu_data(), 
		    		(Dtype)1., bias_diff);
		}
  }
	
	int top_offset_ = height_out_ * width_out_ * num_output_ / group_;
 	int col_offset_ = height_out_ * width_out_ * kernel_size_ * kernel_size_ * channels / group_;
 	int weight_offset_ = kernel_size_ * kernel_size_ * channels * num_output_ / group_ / group_;
 	
	if (this->lr_mult()[0] > 0 && Caffe::frozen_param() == false)
	{
		for (int n = 0; n < num; ++n) 
		{
			im2col_gpu(bottom_data + bottom[0]->offset(n), channels, height,width, 
		  kernel_size_, kernel_size_, pad_, pad_, stride_, stride_, filter_stride_, filter_stride_, 
		  col_data);   
		
			for (int g = 0; g < group_; g++) 
			{
				caffe_gpu_gemm<Dtype>(CblasNoTrans, CblasTrans, num_output_ / group_, kernel_size_*kernel_size_*channels / group_, height_out_*width_out_,
															(Dtype)1., top_diff + top[0]->offset(n) + top_offset_ * g, col_data + col_offset_ * g, 
															(Dtype)1., weight_diff + weight_offset_ * g);
			}												
		}
	}
	
  for (int n = 0; n < num; ++n) 
  {
  	for (int g = 0; g < group_; g++) 
  	{
		  caffe_gpu_gemm<Dtype>(CblasTrans, CblasNoTrans, kernel_size_*kernel_size_*channels/ group_, height_out_*width_out_, num_output_/ group_,
														(Dtype)1., weight + weight_offset_ * g, top_diff + top[0]->offset(n) + top_offset_ * g,
														(Dtype)0., col_diff + col_offset_ * g);
  	}
    col2im_gpu(col_diff,  channels, height, width,  
    kernel_size_, kernel_size_, pad_, pad_, stride_, stride_, filter_stride_, filter_stride_, 
    bottom_diff + bottom[0]->offset(n));
  }     
}

template <typename Dtype>
void ConvolutionLayer<Dtype>::SecForward_gpu(const vector<Blob<Dtype>*>& bottom, const vector<Blob<Dtype>*> &top) 
{

}

INSTANTIATE_LAYER_GPU_FUNCS(ConvolutionLayer);

}  // namespace caffe
