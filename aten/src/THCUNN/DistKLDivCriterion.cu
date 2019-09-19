#include <THCUNN/THCUNN.h>
#include <THCUNN/common.h>
#include <TH/THHalf.h>
#include <THC/THCNumerics.cuh>
#include <THC/THCApply.cuh>

#include <thrust/fill.h>
#include <thrust/functional.h>
#include <thrust/device_ptr.h>
#include <thrust/reduce.h>
#include <thrust/inner_product.h>

template <typename Dtype, typename Acctype>
struct kl_functor
{
  __host__ __device__ Acctype operator()(const Dtype& x, const Dtype& y) const
  {
      Acctype yAcc = ScalarConvert<Dtype, Acctype>::to(y);
      return y > 0 ? yAcc * (std::log(yAcc) - x) : Acctype(0);
  }
};

template <typename Dtype>
struct kl_updateOutput_no_reduce_functor
{
  __forceinline__ __host__ __device__ void operator()(
      const Dtype *x,
      const Dtype *y,
      Dtype *output)
  {
      *output = *y > 0 ? ScalarConvert<int, Dtype>::to(*y * (std::log(*y) - *x)) : ScalarConvert<int, Dtype>::to(0);
  }
};

template <typename Dtype>
struct kl_updateGradInput_no_reduce_functor
{
  __host__ __device__ void operator()(
      const Dtype *target,
      const Dtype *gradOutput,
      Dtype *gradInput)
  {
      *gradInput = *target > 0 ? (-*target) * *gradOutput : ScalarConvert<int, Dtype>::to(0);
  }
};

template <typename Dtype>
struct kl_updateGradInput_functor
{
  const Dtype norm;
  const Dtype gradOutput;

  kl_updateGradInput_functor(Dtype norm_, Dtype gradOutput_)
    : norm(norm_), gradOutput(gradOutput_)
  {}

  __host__ __device__ Dtype operator()(const Dtype& x, const Dtype& y) const
  {
      return y > 0 ? norm * (-y) * gradOutput : ScalarConvert<int, Dtype>::to(0);
  }
};

#include <THCUNN/generic/DistKLDivCriterion.cu>
#include <THC/THCGenerateFloatTypes.h>
