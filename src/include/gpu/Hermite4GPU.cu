/*
 * Copyright (c) 2016
 *
 * Cristián Maureira-Fredes <cmaureirafredes@gmail.com>
 *
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 * 1. Redistributions of source code must retain the above copyright
 * notice, this list of conditions and the following disclaimer.
 *
 * 2. Redistributions in binary form must reproduce the above copyright
 * notice, this list of conditions and the following disclaimer in the
 * documentation and/or other materials provided with the distribution.
 *
 * 3. The name of the author may not be used to endorse or promote
 * products derived from this software without specific prior written
 * permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS
 * OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED.  IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY
 * DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE
 * GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 * INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER
 * IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR
 * OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN
 * IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 */
#undef _GLIBCXX_ATOMIC_BUILTINS
#include "Hermite4GPU.cuh"

/** Constructor that uses its parent one.
 * Additionally handles the split of the particles of the system among the available
 * GPUs, allocation of the variables, and defining widely use sizes for arrays.
 */
Hermite4GPU::Hermite4GPU(NbodySystem *ns, Logger *logger, NbodyUtils *nu)
            : Hermite4(ns, logger, nu)
{
    smem = sizeof(Predictor) * BSIZE;
    smem_reduce = sizeof(Forces) * NJBLOCK + 1;

    int detected_gpus;
    CSC(cudaGetDeviceCount(&detected_gpus));

    if (ns->gpus > 0)
    {
        gpus = ns->gpus;
    }
    else
    {
        gpus = detected_gpus;
    }

    if (detected_gpus > gpus)
    {
        std::string s = "";
        s += std::string("Not using all the available GPUs: ");
        s += std::string(SSTR(gpus));
        s += std::string(" of ");
        s += std::string(SSTR(detected_gpus));
        logger->log_warning(s);
    }

    logger->log_info(std::string("GPUs: ")+std::string(SSTR(gpus)));

    std::string ss = "";
    ss += std::string("Splitting ");
    ss += std::string(SSTR(ns->n));
    ss += std::string(" particles in ");
    ss += std::string(SSTR(gpus));
    ss += std::string(" GPUs");
    logger->log_info(ss);

    if (ns->n % gpus == 0)
    {
        size_t size = ns->n/gpus;
        for ( int g = 0; g < gpus; g++)
            n_part[g] = size;
    }
    else
    {
        size_t size = std::ceil(ns->n/(float)gpus);
        for ( int g = 0; g < gpus; g++)
        {
            if (ns->n - size*(g+1) > 0)
                n_part[g] = size;
            else
                n_part[g] = ns->n - size*g;
        }
    }

    for(int g = 0; g < gpus; g++)
    {
        std::string sss = "";
        sss += std::string("GPU ");
        sss += std::string(SSTR(g));
        sss += std::string(" particles: ");
        sss += std::string(SSTR(n_part[g]));
        logger->log_info(sss);
    }

    i1_size = ns->n * sizeof(int);
    d1_size = ns->n * sizeof(double);
    d4_size = ns->n * sizeof(double4);
    ff_size = ns->n * sizeof(Forces);
    pp_size = ns->n * sizeof(Predictor);

    alloc_arrays_device();
}

/** Destructor in charge of memory deallocation */
Hermite4GPU::~Hermite4GPU()
{
    free_arrays_device();
}

/** Method in charge of allocating the data structures on the available GPUs,
 * also initializing all the arrays to zero
 */
void Hermite4GPU::alloc_arrays_device()
{
    for(int g = 0; g < gpus; g++)
    {
        // Setting GPU
        CSC(cudaSetDevice(g));

        CSC(cudaMalloc((void**)&ns->d_r[g], d4_size));
        CSC(cudaMalloc((void**)&ns->d_v[g], d4_size));
        CSC(cudaMalloc((void**)&ns->d_f[g], ff_size));
        CSC(cudaMalloc((void**)&ns->d_p[g], pp_size));
        CSC(cudaMalloc((void**)&ns->d_t[g], d1_size));
        CSC(cudaMalloc((void**)&ns->d_i[g], pp_size));
        CSC(cudaMalloc((void**)&ns->d_dt[g], d1_size));
        CSC(cudaMalloc((void**)&ns->d_ekin[g], d1_size));
        CSC(cudaMalloc((void**)&ns->d_epot[g], d1_size));
        CSC(cudaMalloc((void**)&ns->d_move[g], i1_size));
        CSC(cudaMalloc((void**)&ns->d_fout[g], ff_size * NJBLOCK));
        CSC(cudaMalloc((void**)&ns->d_fout_tmp[g], ff_size * NJBLOCK));

        CSC(cudaMemset(ns->d_r[g], 0, d4_size));
        CSC(cudaMemset(ns->d_v[g], 0, d4_size));
        CSC(cudaMemset(ns->d_f[g], 0, ff_size));
        CSC(cudaMemset(ns->d_p[g], 0, pp_size));
        CSC(cudaMemset(ns->d_t[g], 0, d1_size));
        CSC(cudaMemset(ns->d_i[g], 0, pp_size));
        CSC(cudaMemset(ns->d_dt[g], 0, d1_size));
        CSC(cudaMemset(ns->d_ekin[g], 0, d1_size));
        CSC(cudaMemset(ns->d_epot[g], 0, d1_size));
        CSC(cudaMemset(ns->d_move[g], 0, i1_size));
        CSC(cudaMemset(ns->d_fout[g], 0, ff_size * NJBLOCK));
        CSC(cudaMemset(ns->d_fout_tmp[g], 0, ff_size * NJBLOCK));

        ns->h_fout_gpu[g] = new Forces[ns->n*NJBLOCK];
    }

    // Extra CPU array
    ns->h_fout_tmp = new Forces[ns->n*NJBLOCK];
}

/** Method in charge of deallocating the data structures on the available GPUs.
 */
void Hermite4GPU::free_arrays_device()
{

    for(int g = 0; g < gpus; g++)
    {
        // Setting GPU
        CSC(cudaSetDevice(g));

        CSC(cudaFree(ns->d_r[g]));
        CSC(cudaFree(ns->d_v[g]));
        CSC(cudaFree(ns->d_f[g]));
        CSC(cudaFree(ns->d_p[g]));
        CSC(cudaFree(ns->d_t[g]));
        CSC(cudaFree(ns->d_i[g]));
        CSC(cudaFree(ns->d_dt[g]));
        CSC(cudaFree(ns->d_ekin[g]));
        CSC(cudaFree(ns->d_epot[g]));
        CSC(cudaFree(ns->d_move[g]));
        CSC(cudaFree(ns->d_fout[g]));
        CSC(cudaFree(ns->d_fout_tmp[g]));
        delete ns->h_fout_gpu[g];
    }

    delete ns->h_fout_tmp;
    //delete ns->h_fout_gpu;
}

/** Method in charge of the prediction step.
 * This can be use on the CPU (commented section) or on the GPUs.
 * The reason of having both reasons, is the improvement is not much for small
 * amount of particles.
 */
void Hermite4GPU::predicted_pos_vel(double ITIME)
{
    ns->gtime.prediction_ini = omp_get_wtime();
    //#pragma omp parallel for
    //for (int i = 0; i < ns->n; i++)
    //{
    //    double dt  = ITIME - ns->h_t[i];
    //    double dt2 = 0.5*(dt  * dt);
    //    double dt3 = 0.166666666666666*(dt * dt * dt);

    //    Forces ff = ns->h_f[i];
    //    double4 rr = ns->h_r[i];
    //    double4 vv = ns->h_v[i];

    //    ns->h_p[i].r[0] = (dt3 * ff.a1[0]) + (dt2 * ff.a[0]) + (dt * vv.x) + rr.x;
    //    ns->h_p[i].r[1] = (dt3 * ff.a1[1]) + (dt2 * ff.a[1]) + (dt * vv.y) + rr.y;
    //    ns->h_p[i].r[2] = (dt3 * ff.a1[2]) + (dt2 * ff.a[2]) + (dt * vv.z) + rr.z;

    //    ns->h_p[i].v[0] = (dt2 * ff.a1[0]) + (dt * ff.a[0]) + vv.x;
    //    ns->h_p[i].v[1] = (dt2 * ff.a1[1]) + (dt * ff.a[1]) + vv.y;
    //    ns->h_p[i].v[2] = (dt2 * ff.a1[2]) + (dt * ff.a[2]) + vv.z;

    //    ns->h_p[i].m = rr.w;
    //}

    for(int g = 0; g < gpus; g++)
    {
        CSC(cudaSetDevice(g));
        int shift = g*n_part[g-1];
        size_t ff_size = n_part[g] * sizeof(Forces);
        size_t d4_size = n_part[g] * sizeof(double4);
        size_t d1_size = n_part[g] * sizeof(double);

        CSC(cudaMemcpyAsync(ns->d_f[g], ns->h_f + shift, ff_size, cudaMemcpyHostToDevice, 0));
        CSC(cudaMemcpyAsync(ns->d_r[g], ns->h_r + shift, d4_size, cudaMemcpyHostToDevice, 0));
        CSC(cudaMemcpyAsync(ns->d_v[g], ns->h_v + shift, d4_size, cudaMemcpyHostToDevice, 0));
        CSC(cudaMemcpyAsync(ns->d_t[g], ns->h_t + shift, d1_size, cudaMemcpyHostToDevice, 0));
    }

    // Executing kernels
    for(int g = 0; g < gpus; g++)
    {
        CSC(cudaSetDevice(g));

        nthreads = BSIZE;
        nblocks = std::ceil(n_part[g]/(float)nthreads);

        k_prediction <<< nblocks, nthreads >>> (ns->d_f[g],
                                                ns->d_r[g],
                                                ns->d_v[g],
                                                ns->d_t[g],
                                                ns->d_p[g],
                                                n_part[g],
                                                ITIME);
        get_kernel_error();
    }

    for(int g = 0; g < gpus; g++)
    {
        CSC(cudaSetDevice(g));
        size_t slice = g*n_part[g-1];
        size_t pp_size = n_part[g] * sizeof(Predictor);

        CSC(cudaMemcpyAsync(&ns->h_p[slice], ns->d_p[g], pp_size, cudaMemcpyDeviceToHost, 0));
    }

    ns->gtime.prediction_end += omp_get_wtime() - ns->gtime.prediction_ini;
}

/** Method in charge of the corrector step.
 * This is not implemented on the GPU because the benefit was not much
 * for small amount of particles.
 */
void Hermite4GPU::correction_pos_vel(double ITIME, int nact)
{
    ns->gtime.correction_ini = omp_get_wtime();
    int i;
    #pragma omp parallel for private(i)
    for (int k = 0; k < nact; k++)
    {
        i = ns->h_move[k];

        Forces ff = ns->h_f[i];
        Forces oo = ns->h_old[i];
        Predictor pp = ns->h_p[i];

        double dt1 = ns->h_dt[i];
        double dt2 = dt1 * dt1;
        double dt3 = dt2 * dt1;
        double dt4 = dt2 * dt2;
        double dt5 = dt4 * dt1;

        double dt2inv = 1.0/dt2;
        double dt3inv = 1.0/dt3;

        double dt3_6 = 0.166666666666666*dt3;
        double dt4_24 = 0.041666666666666*dt4;
        double dt5_120 = 0.008333333333333*dt5;

        // Acceleration 2nd derivate
        ns->h_a2[i].x = (-6 * (oo.a[0] - ff.a[0] ) - dt1 * (4 * oo.a1[0] + 2 * ff.a1[0]) ) * dt2inv;
        ns->h_a2[i].y = (-6 * (oo.a[1] - ff.a[1] ) - dt1 * (4 * oo.a1[1] + 2 * ff.a1[1]) ) * dt2inv;
        ns->h_a2[i].z = (-6 * (oo.a[2] - ff.a[2] ) - dt1 * (4 * oo.a1[2] + 2 * ff.a1[2]) ) * dt2inv;

        // Acceleration 3rd derivate
        ns->h_a3[i].x = (12 * (oo.a[0] - ff.a[0] ) + 6 * dt1 * (oo.a1[0] + ff.a1[0]) ) * dt3inv;
        ns->h_a3[i].y = (12 * (oo.a[1] - ff.a[1] ) + 6 * dt1 * (oo.a1[1] + ff.a1[1]) ) * dt3inv;
        ns->h_a3[i].z = (12 * (oo.a[2] - ff.a[2] ) + 6 * dt1 * (oo.a1[2] + ff.a1[2]) ) * dt3inv;


        // Correcting position
        ns->h_r[i].x = pp.r[0] + (dt4_24)*ns->h_a2[i].x + (dt5_120)*ns->h_a3[i].x;
        ns->h_r[i].y = pp.r[1] + (dt4_24)*ns->h_a2[i].y + (dt5_120)*ns->h_a3[i].y;
        ns->h_r[i].z = pp.r[2] + (dt4_24)*ns->h_a2[i].z + (dt5_120)*ns->h_a3[i].z;

        // Correcting velocity
        ns->h_v[i].x = pp.v[0] + (dt3_6)*ns->h_a2[i].x + (dt4_24)*ns->h_a3[i].x;
        ns->h_v[i].y = pp.v[1] + (dt3_6)*ns->h_a2[i].y + (dt4_24)*ns->h_a3[i].y;
        ns->h_v[i].z = pp.v[2] + (dt3_6)*ns->h_a2[i].z + (dt4_24)*ns->h_a3[i].z;

        ns->h_t[i] = ITIME;

        double normal_dt  = nu->get_timestep_normal(i, ns->eta);
        ns->h_dt[i] = nu->normalize_dt(normal_dt, ns->h_dt[i], ns->h_t[i], i);

    }
    ns->gtime.correction_end += omp_get_wtime() - ns->gtime.correction_ini;
}

/** Method in charge of the initialization of all the particle's acceleration
 * and first derivative of the system, at the begining of the simulation.
 */
void Hermite4GPU::init_acc_jrk()
{
    size_t pp_size = ns->n * sizeof(Predictor);

    // Copying arrays to device
    #pragma omp parallel for num_threads(gpus)
    for(int g = 0; g < gpus; g++)
    {
        CSC(cudaSetDevice(g));

        // All this information from the predictors is needed by each device
        CSC(cudaMemcpy(ns->d_p[g], ns->h_p, pp_size, cudaMemcpyHostToDevice));
        //CSC(cudaMemcpyAsync(ns->d_p[g], ns->h_p, pp_size, cudaMemcpyHostToDevice, 0));
    }

    // Executing kernels
    for(int g = 0; g < gpus; g++)
    {
        CSC(cudaSetDevice(g));

        nthreads = BSIZE;
        nblocks = std::ceil(n_part[g]/(float)nthreads);

        k_init_acc_jrk <<< nblocks, nthreads, smem >>> (ns->d_p[g],
                                                        ns->d_f[g],
                                                        ns->n,
                                                        ns->e2,
                                                        g,
                                                        n_part[g]);
        get_kernel_error();
    }

    for(int g = 0; g < gpus; g++)
    {
        CSC(cudaSetDevice(g));

        size_t chunk = n_part[g]*sizeof(Forces);
        size_t slice = g*n_part[g-1];

        CSC(cudaMemcpy(&ns->h_f[slice], ns->d_f[g], chunk, cudaMemcpyDeviceToHost));
        //CSC(cudaMemcpyAsync(&ns->h_f[slice], ns->d_f[g], chunk, cudaMemcpyDeviceToHost, 0));
    }
}

/** Method in charge of the force interaction between \f$N_{act}\f$ and the whole
 * system.
 *  First there is a tmp construction of predictors to be send to the GPUs.
 *  Then the data is copied to the devices.
 *  The first kernel perform the preliminary calculation of the forces in JPBLOCKS.
 *  The second kernel, reduction, is in charge of summing all the preliminary forces
 *  to the final value for all the active particles.
 */
void Hermite4GPU::update_acc_jrk(int nact)
{
    // Timer begin
    ns->gtime.update_ini = omp_get_wtime();

    //for(int g = 0; g < gpus; g++)
    //{
    //    if (n_part[g] > 0)
    //    {
    //        size_t pp_size = n_part[g] * sizeof(Predictor);
    //        int shift = g*n_part[g-1];

    //        CSC(cudaSetDevice(g));
    //        // Copying to the device the predicted r and v
    //        //CSC(cudaMemcpy(ns->d_p[g], ns->h_p + shift, pp_size, cudaMemcpyHostToDevice));
    //        CSC(cudaMemcpyAsync(ns->d_p[g], ns->h_p + shift, pp_size, cudaMemcpyHostToDevice, 0));
    //    }
    //}

    // Fill the h_i Predictor array with the particles that we need to move
    #pragma omp parallel for
    for (int i = 0; i < nact; i++)
    {
        ns->h_i[i] = ns->h_p[ns->h_move[i]];
    }

    for(int g = 0; g < gpus; g++)
    {
        if (n_part[g] > 0)
        {
            CSC(cudaSetDevice(g));
            // Copy to the GPU (d_i) the preddictor host array (h_i)
            size_t chunk = nact * sizeof(Predictor);
            //CSC(cudaMemcpy(ns->d_i[g], ns->h_i, chunk, cudaMemcpyHostToDevice));
            CSC(cudaMemcpyAsync(ns->d_i[g], ns->h_i, chunk, cudaMemcpyHostToDevice, 0));
        }
    }

    ns->gtime.grav_ini = omp_get_wtime();
    for(int g = 0; g < gpus; g++)
    {
        if (n_part[g] > 0)
        {
            CSC(cudaSetDevice(g));
            // Blocks, threads and shared memory configuration
            int  nact_blocks = 1 + (nact-1)/BSIZE;
            dim3 nblocks(nact_blocks, NJBLOCK, 1);
            dim3 nthreads(BSIZE, 1, 1);

            // Kernel to update the forces for the particles in d_i
            k_update <<< nblocks, nthreads, smem >>> (ns->d_i[g],
                                                      ns->d_p[g], // partial
                                                      ns->d_fout[g],
                                                      n_part[g], // former N
                                                      nact,
                                                      ns->e2);
        }
    }

    ns->gtime.grav_end += omp_get_wtime() - ns->gtime.grav_ini;

    ns->gtime.reduce_ini = omp_get_wtime();
    for(int g = 0; g < gpus; g++)
    {
        size_t chunk = 2<<14;
        if (n_part[g] > 0)
        {
            CSC(cudaSetDevice(g));
            // Blocks, threads and shared memory configuration for the reduction.
            if (nact <= chunk) // limit 32768
            {
                dim3 rgrid   (nact,   1, 1);
                dim3 rthreads(NJBLOCK, 1, 1);

                // Kernel to reduce que temp array with the forces
                k_reduce <<< rgrid, rthreads, smem_reduce >>>(ns->d_fout[g],
                                                            ns->d_fout_tmp[g],
                                                            0,
                                                            0);
            }
            else
            {

                int smax = std::ceil(nact/(float)chunk);
                unsigned int shift = 0;
                size_t size_launch = 0;

                for(unsigned int s = 0; shift < nact; s++)
                {
                    // shift_id : s
                    // shift: moving pointer
                    // size_launch: chunk to multipy by Forces size
                    if (nact < shift + chunk)
                        size_launch = nact-shift;
                    else
                        size_launch = chunk;

                    dim3 rgrid   (size_launch,   1, 1);
                    dim3 rthreads(NJBLOCK, 1, 1);
                    k_reduce <<< rgrid, rthreads, smem_reduce >>>(ns->d_fout[g],
                                                                  ns->d_fout_tmp[g]+shift,
                                                                  s,
                                                                  shift);


                    shift += chunk;
                }
            }
        }
    }
    ns->gtime.reduce_end += omp_get_wtime() - ns->gtime.reduce_ini;

    for(int g = 0; g < gpus; g++)
    {
        if (n_part[g] > 0)
        {
            CSC(cudaSetDevice(g));
            size_t chunk = nact*sizeof(Forces);

            // Copy from the GPU the new forces for the d_i particles.
            //CSC(cudaMemcpy(ns->h_fout_gpu[g], ns->d_fout_tmp[g], chunk, cudaMemcpyDeviceToHost));
            CSC(cudaMemcpyAsync(ns->h_fout_gpu[g], ns->d_fout_tmp[g], chunk, cudaMemcpyDeviceToHost, 0));
        }
    }

    // Update forces in the host
    ns->gtime.reduce_forces_ini = omp_get_wtime();
    #pragma omp parallel for
    for (int i = 0; i < nact; i++)
    {
        int id = ns->h_move[i];
        ns->h_f[id].a[0] = 0.0;
        ns->h_f[id].a[1] = 0.0;
        ns->h_f[id].a[2] = 0.0;
        ns->h_f[id].a1[0] = 0.0;
        ns->h_f[id].a1[1] = 0.0;
        ns->h_f[id].a1[2] = 0.0;

        for(int g = 0; g < gpus; g++)
        {
            if (n_part[g] > 0)
            {
                ns->h_f[id] += ns->h_fout_gpu[g][i];
            }
        }
    }
    ns->gtime.reduce_forces_end += omp_get_wtime() - ns->gtime.reduce_forces_ini;

    // Timer end
    ns->gtime.update_end += (omp_get_wtime() - ns->gtime.update_ini);
}

/** Method in charge of calculating the potential and kinetic energy
 * on the GPU devices
 */
double Hermite4GPU::get_energy_gpu()
{
    double time_energy_ini = omp_get_wtime();

    size_t d4_size = ns->n * sizeof(double4);

    for(int g = 0; g < gpus; g++)
    {
        CSC(cudaSetDevice(g));

        CSC(cudaMemcpyAsync(ns->d_r[g], ns->h_r, d4_size, cudaMemcpyHostToDevice, 0));
        CSC(cudaMemcpyAsync(ns->d_v[g], ns->h_v, d4_size, cudaMemcpyHostToDevice, 0));
    }

    int nthreads = BSIZE;
    for(int g = 0; g < gpus; g++)
    {
        CSC(cudaSetDevice(g));

        int nblocks = std::ceil(n_part[g]/(float)nthreads);
        k_energy <<< nblocks, nthreads >>> (ns->d_r[g],
                                            ns->d_v[g],
                                            ns->d_ekin[g],
                                            ns->d_epot[g],
                                            ns->n,
                                            n_part[g],
                                            g);
    }

    for(int g = 0; g < gpus; g++)
    {
        CSC(cudaSetDevice(g));

        size_t chunk = n_part[g]*sizeof(double);
        size_t slice = g*n_part[g-1];

        CSC(cudaMemcpyAsync(&ns->h_ekin[slice], ns->d_ekin[g], chunk, cudaMemcpyDeviceToHost, 0));
        CSC(cudaMemcpyAsync(&ns->h_epot[slice], ns->d_epot[g], chunk, cudaMemcpyDeviceToHost, 0));
    }

    // Reduction on CPU
    ns->en.kinetic = 0.0;
    ns->en.potential = 0.0;
    for (int i = 0; i < ns->n; i++)
    {
        ns->en.kinetic   += ns->h_ekin[i];
        ns->en.potential += ns->h_epot[i];
    }

    double time_energy_end = omp_get_wtime() - time_energy_ini;

    return ns->en.kinetic + ns->en.potential;
}

/** Method that get the last kernel error if the code is running with the DEBUG
 * flag
 */
void Hermite4GPU::get_kernel_error()
{
    #ifdef KERNEL_ERROR_DEBUG
    logger->log_error(std::string(cudaGetErrorString(cudaGetLastError())));
    #endif
}

/** Method to start the device timer
 */
void Hermite4GPU::gpu_timer_start(){
    cudaEventRecord(start);
}

/** Method that ends the device timer
 */
float Hermite4GPU::gpu_timer_stop(std::string f){
    cudaEventRecord(stop);
    cudaEventSynchronize(stop);
    float msec = 0;
    cudaEventElapsedTime(&msec, start, stop);
    #if KERNEL_TIME
    if (f != "")
    {
        std::string s = "";
        s += std::string("Kernel ");
        s += std::string(SSTR(f));
        s += std::string(" : ");
        s += std::string(SSTR(msec));
        logger->log_info(s)
    }
    #endif
    return msec;
}

/** This method is not implemented becasue we use a CUDA kernel
 * to perfom the force calculation, not a host method.
 rkarim: copied the CPU version in because we're using it now
 */
void Hermite4GPU::force_calculation(const Predictor &pi, const Predictor &pj, Forces &fi) {
  double rx = pj.r[0] - pi.r[0];
  double ry = pj.r[1] - pi.r[1];
  double rz = pj.r[2] - pi.r[2];

  double vx = pj.v[0] - pi.v[0];
  double vy = pj.v[1] - pi.v[1];
  double vz = pj.v[2] - pi.v[2];

  double r2     = rx*rx + ry*ry + rz*rz + ns->e2;
  double rinv   = 1.0/sqrt(r2);
  double r2inv  = rinv  * rinv;
  double r3inv  = r2inv * rinv;
  double r5inv  = r2inv * r3inv;
  double mr3inv = r3inv * pj.m;
  double mr5inv = r5inv * pj.m;

  double rv = rx*vx + ry*vy + rz*vz;

  fi.a[0] += (rx * mr3inv);
  fi.a[1] += (ry * mr3inv);
  fi.a[2] += (rz * mr3inv);

  fi.a1[0] += (vx * mr3inv - (3 * rv ) * rx * mr5inv);
  fi.a1[1] += (vy * mr3inv - (3 * rv ) * ry * mr5inv);
  fi.a1[2] += (vz * mr3inv - (3 * rv ) * rz * mr5inv);
}

/**
BELOW HERE IS CPU ONLY, copied from cpu/Hermite4CPU.cpp
**/

/** Method that call the force_calculation method for every \f$i-\f$ and \f$j\f$
 * particles interaction of the \f$N_{act}\f$ ones.
 */
void Hermite4GPU::update_acc_jrk_cpu(unsigned int nact)
{
    ns->gtime.update_ini = omp_get_wtime();
    unsigned int i = 0;
    unsigned int j = 0;
    #pragma omp parallel for private(i,j)
    for (unsigned int k = 0; k < nact; k++)
    {
        i = ns->h_move[k];
        ns->h_f[i].a[0]  = 0.0;
        ns->h_f[i].a[1]  = 0.0;
        ns->h_f[i].a[2]  = 0.0;
        ns->h_f[i].a1[0] = 0.0;
        ns->h_f[i].a1[1] = 0.0;
        ns->h_f[i].a1[2] = 0.0;

        #pragma omp parallel for
        for (j = 0; j < ns->n; j++)
        {
            if(i == j) continue;
            force_calculation(ns->h_p[i], ns->h_p[j], ns->h_f[i]);
            // #ifdef PN
            // force_calculation_pn(ns->h_p[i], ns->h_p[j], ns->h_f[i], ns->h_f[j], i);
            // #endif
        }
    }
    ns->gtime.update_end += omp_get_wtime() - ns->gtime.update_ini;
}
