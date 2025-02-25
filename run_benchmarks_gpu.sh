#!/usr/bin/env bash

nrun=1000
NDIM=256

for n in {1,4,8};
do
    export OMP_NUM_THREADS=$n

    ./benchmarker_cgdrag_forpy ../cgdrag_model run_emulator_davenet      $nrun 10                                               | tee cgdrag_forpy_$n.out
    ./benchmarker_cgdrag_torch ../cgdrag_model saved_cgdrag_model_gpu.pt $nrun 10 --alloc_in_loop --explicit_reshape --use_cuda | tee cgdrag_torch_explicit_gpu_$n.out
    ./benchmarker_cgdrag_torch ../cgdrag_model saved_cgdrag_model_gpu.pt $nrun 10 --use_cuda                                    | tee cgdrag_torch_implicit_gpu_$n.out

    ./benchmarker_resnet_forpy ../resnet_model resnet18                    $nrun 10            | tee resnet_forpy_$n.out
    ./benchmarker_resnet_torch ../resnet_model saved_resnet18_model_gpu.pt $nrun 10 --use_cuda | tee resnet_torch_gpu_$n.out

    ./benchmarker_large_stride_forpy ../large_stride_model run_emulator_stride             $nrun $NDIM            | tee ls_forpy_$n.out
    ./benchmarker_large_stride_torch ../large_stride_model saved_large_stride_model_gpu.pt $nrun $NDIM --use_cuda | tee ls_torch_gpu_$n.out
done
