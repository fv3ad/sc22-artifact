# Setup

There are two options to create the Docker container:
  * An image is available via Docker Hub: `docker pull tbennun/fv3-sc22:latest` (or `sarus pull` on Piz Daint)
  * The Dockerfile and all associated scripts can be built from the files in this repository. Use the following command: `docker build -t <some tag> -f ./artifact.Dockerfile .`
  
# Requirements

Running the container requires Docker and the [NVIDIA Docker runtime](https://github.com/NVIDIA/nvidia-docker) in order to expose the GPU to the container.

If you encounter a `missing libcuda.so` error or the GPU is not found, make sure you are running `nvidia-docker` or `docker --runtime=nvidia`.

# Running 

## Large-scale runs

To run the full workload, at least 6 ranks (each with its own GPU) are necessary. Each rank will start up its own container, as shown in the following example using the SLURM job scheduler:
```
srun -N 6 nvidia-docker run tbennun/fv3-sc22:latest bash /runner.sh
```

or, if on Piz Daint (where the container was tested), Sarus can be used to connect the container to the native MPI implementation and GPU:
```
module load sarus
srun -N 6 sarus run --mpi tbennun/fv3-sc22:latest bash /runner.sh
```

The input can be changed using the `NAMELIST` container environment variable. By default, it runs the 192x192 grid run (`c192_6ranks_baroclinic`). If you want to change this behavior,
you can run the container with another value, e.g., `-eNAMELIST="/c3456_1944ranks_baroclinic/"`

The number of time-steps (`TIMESTEPS`) can similarly be changed with, for example, `-eTIMESTEPS=30`.

## Small-scale runs

We also include a small grid that can be run on a single GPU (albeit with MPI, since communication is hardcoded into the model), and a script that runs OpenMPI within the container.
In order to do so, make sure the [CUDA Multi-Process Service](https://docs.nvidia.com/deploy/mps/index.html) is enabled (in most systems, it is enabled by default), and run:

```
nvidia-docker run tbennun/fv3-sc22:latest bash /runner_local.sh
```

## Caching builds to save time

The runner scripts (`runner[_local].sh`) work in two phases: Build (which will compile the SDFG to execute) and Run (which will run the code for performance). The two can be split to be built and run separately, but it is beneficial to compile the code on the target architecture for improved performance. Since the Docker container filesystem is volatile, all progress is lost once the container finishes running.

To avoid losing the cached build, our script defaults to run on a specific folder (`/home/user`), which can be mounted locally with the following flag:
```
--mount type=bind,source=/PATH/OUTSIDE/CONTAINER,target=/home/user
```

The `FV3_DACEMODE` container environment variable controls the phases (Build, Run).
To run each of the phases separately, you can thus use the following set of commands (demonstrated with the local runner):

```sh
$ mkdir cache
$ docker run --runtime=nvidia -eFV3_DACEMODE=Build --mount type=bind,source=/path/to/cache,target=/home/user tbennun/fv3-sc22:latest bash /runner_local.sh
...runs for a while...
$ docker run --runtime=nvidia -eFV3_DACEMODE=Run --mount type=bind,source=/path/to/cache,target=/home/user tbennun/fv3-sc22:latest bash /runner_local.sh
```


## Baseline

In order to run the baseline FORTRAN version, refer to the README in https://github.com/ai2cm/fv3gfs-fortran/tree/9030cf9c9241d087e8fcdef71ab9458aee980609
The benchmark input folders provided here are compatible with the FORTRAN version.


# File structure

* `c*_*ranks_baroclinic`: Folders containing benchmark inputs for the given number of ranks
* `artifact.Dockerfile`: Docker container setup script
* `c576_54ranks_A100.log`: Log file containing the output of the 54-GPU run on NVIDIA A100 GPUs
* `daint_logs.tar.xz`: A zip file containing all logs from the scaling experiments on Piz Daint
* `plotting.py`: Plots the scaling figure from the paper (uses `data.csv` from `daint_logs.tar.xz`)
* `README.md`: This file
* `runner.sh`: Runner script used in Docker container
* `runner_local.sh`: Runner script that can run the Docker container on a local node
