/* ============================================================

Copyright (c) 2009 Advanced Micro Devices, Inc.  All rights reserved.
 
Redistribution and use of this material is permitted under the following 
conditions:
 
Redistributions must retain the above copyright notice and all terms of this 
license.
 
In no event shall anyone redistributing or accessing or using this material 
commence or participate in any arbitration or legal action relating to this 
material against Advanced Micro Devices, Inc. or any copyright holders or 
contributors. The foregoing shall survive any expiration or termination of 
this license or any agreement or access or use related to this material. 

ANY BREACH OF ANY TERM OF THIS LICENSE SHALL RESULT IN THE IMMEDIATE REVOCATION 
OF ALL RIGHTS TO REDISTRIBUTE, ACCESS OR USE THIS MATERIAL.

THIS MATERIAL IS PROVIDED BY ADVANCED MICRO DEVICES, INC. AND ANY COPYRIGHT 
HOLDERS AND CONTRIBUTORS "AS IS" IN ITS CURRENT CONDITION AND WITHOUT ANY 
REPRESENTATIONS, GUARANTEE, OR WARRANTY OF ANY KIND OR IN ANY WAY RELATED TO 
SUPPORT, INDEMNITY, ERROR FREE OR UNINTERRUPTED OPERA TION, OR THAT IT IS FREE 
FROM DEFECTS OR VIRUSES.  ALL OBLIGATIONS ARE HEREBY DISCLAIMED - WHETHER 
EXPRESS, IMPLIED, OR STATUTORY - INCLUDING, BUT NOT LIMITED TO, ANY IMPLIED 
WARRANTIES OF TITLE, MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE, 
ACCURACY, COMPLETENESS, OPERABILITY, QUALITY OF SERVICE, OR NON-INFRINGEMENT. 
IN NO EVENT SHALL ADVANCED MICRO DEVICES, INC. OR ANY COPYRIGHT HOLDERS OR 
CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, PUNITIVE,
EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT
OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, REVENUE, DATA, OR PROFITS; OR 
BUSINESS INTERRUPTION) HOWEVER CAUSED OR BASED ON ANY THEORY OF LIABILITY 
ARISING IN ANY WAY RELATED TO THIS MATERIAL, EVEN IF ADVISED OF THE POSSIBILITY 
OF SUCH DAMAGE. THE ENTIRE AND AGGREGATE LIABILITY OF ADVANCED MICRO DEVICES, 
INC. AND ANY COPYRIGHT HOLDERS AND CONTRIBUTORS SHALL NOT EXCEED TEN DOLLARS 
(US $10.00). ANYONE REDISTRIBUTING OR ACCESSING OR USING THIS MATERIAL ACCEPTS 
THIS ALLOCATION OF RISK AND AGREES TO RELEASE ADVANCED MICRO DEVICES, INC. AND 
ANY COPYRIGHT HOLDERS AND CONTRIBUTORS FROM ANY AND ALL LIABILITIES, 
OBLIGATIONS, CLAIMS, OR DEMANDS IN EXCESS OF TEN DOLLARS (US $10.00). THE 
FOREGOING ARE ESSENTIAL TERMS OF THIS LICENSE AND, IF ANY OF THESE TERMS ARE 
CONSTRUED AS UNENFORCEABLE, FAIL IN ESSENTIAL PURPOSE, OR BECOME VOID OR 
DETRIMENTAL TO ADVANCED MICRO DEVICES, INC. OR ANY COPYRIGHT HOLDERS OR 
CONTRIBUTORS FOR ANY REASON, THEN ALL RIGHTS TO REDISTRIBUTE, ACCESS OR USE 
THIS MATERIAL SHALL TERMINATE IMMEDIATELY. MOREOVER, THE FOREGOING SHALL 
SURVIVE ANY EXPIRATION OR TERMINATION OF THIS LICENSE OR ANY AGREEMENT OR 
ACCESS OR USE RELATED TO THIS MATERIAL.

NOTICE IS HEREBY PROVIDED, AND BY REDISTRIBUTING OR ACCESSING OR USING THIS 
MATERIAL SUCH NOTICE IS ACKNOWLEDGED, THAT THIS MATERIAL MAY BE SUBJECT TO 
RESTRICTIONS UNDER THE LAWS AND REGULATIONS OF THE UNITED STATES OR OTHER 
COUNTRIES, WHICH INCLUDE BUT ARE NOT LIMITED TO, U.S. EXPORT CONTROL LAWS SUCH 
AS THE EXPORT ADMINISTRATION REGULATIONS AND NATIONAL SECURITY CONTROLS AS 
DEFINED THEREUNDER, AS WELL AS STATE DEPARTMENT CONTROLS UNDER THE U.S. 
MUNITIONS LIST. THIS MATERIAL MAY NOT BE USED, RELEASED, TRANSFERRED, IMPORTED,
EXPORTED AND/OR RE-EXPORTED IN ANY MANNER PROHIBITED UNDER ANY APPLICABLE LAWS, 
INCLUDING U.S. EXPORT CONTROL LAWS REGARDING SPECIFICALLY DESIGNATED PERSONS, 
COUNTRIES AND NATIONALS OF COUNTRIES SUBJECT TO NATIONAL SECURITY CONTROLS. 
MOREOVER, THE FOREGOING SHALL SURVIVE ANY EXPIRATION OR TERMINATION OF ANY 
LICENSE OR AGREEMENT OR ACCESS OR USE RELATED TO THIS MATERIAL.

NOTICE REGARDING THE U.S. GOVERNMENT AND DOD AGENCIES: This material is 
provided with "RESTRICTED RIGHTS" and/or "LIMITED RIGHTS" as applicable to 
computer software and technical data, respectively. Use, duplication, 
distribution or disclosure by the U.S. Government and/or DOD agencies is 
subject to the full extent of restrictions in all applicable regulations, 
including those found at FAR52.227 and DFARS252.227 et seq. and any successor 
regulations thereof. Use of this material by the U.S. Government and/or DOD 
agencies is acknowledgment of the proprietary rights of any copyright holders 
and contributors, including those of Advanced Micro Devices, Inc., as well as 
the provisions of FAR52.227-14 through 23 regarding privately developed and/or 
commercial computer software.

This license forms the entire agreement regarding the subject matter hereof and 
supersedes all proposals and prior discussions and writings between the parties 
with respect thereto. This license does not affect any ownership, rights, title,
or interest in, or relating to, this material. No terms of this license can be 
modified or waived, and no breach of this license can be excused, unless done 
so in a writing signed by all affected parties. Each term of this license is 
separately enforceable. If any term of this license is determined to be or 
becomes unenforceable or illegal, such term shall be reformed to the minimum 
extent necessary in order for this license to remain in effect in accordance 
with its terms as modified by such reformation. This license shall be governed 
by and construed in accordance with the laws of the State of Texas without 
regard to rules on conflicts of law of any state or jurisdiction or the United 
Nations Convention on the International Sale of Goods. All disputes arising out 
of this license shall be subject to the jurisdiction of the federal and state 
courts in Austin, Texas, and all defenses are hereby waived concerning personal 
jurisdiction and venue of these courts.

============================================================ */


#include "CPUVsGPUTest.hpp"

/*
 * \brief Host Initialization 
 *        Allocate and initialize memory 
 *        on the host. Print input array. 
 */
int
initializeHost(void)
{
    width				= 1024*1024*4;//*32;//256;
    inputA				= NULL;
	inputB				= NULL;
    outputC				= NULL;
    multiplier			= 2;
	cpu					= true;

    /////////////////////////////////////////////////////////////////
    // Allocate and initialize memory used by host 
    /////////////////////////////////////////////////////////////////
    cl_uint sizeInBytes = width * sizeof(cl_double);
    inputA = (cl_double *) malloc(sizeInBytes);
	inputB = (cl_double *) malloc(sizeInBytes);
    if(inputA == NULL || inputB == NULL)
    {
        std::cout<<"Error: Failed to allocate input memory on host\n";
        return 1; 
    }

    outputC = (cl_double *) malloc(sizeInBytes);
    if(outputC == NULL)
    {
        std::cout<<"Error: Failed to allocate output memory on host\n";
        return 1; 
    }

    for(cl_uint i = 0; i < width; i++)
	{
		inputA[i] = i;
		inputB[i] = i*i;
	}

    // print input arrays
    //print1DArray(std::string("Input A").c_str(), inputA, width);
	//print1DArray(std::string("Input B").c_str(), inputB, width);
    return 0;
}

/*
 * Converts the contents of a file into a string
 */
std::string
convertToString(const char *filename)
{
    size_t size;
    char*  str;
    std::string s;

    std::fstream f(filename, (std::fstream::in | std::fstream::binary));

    if(f.is_open())
    {
        size_t fileSize;
        f.seekg(0, std::fstream::end);
        size = fileSize = (size_t)f.tellg();
        f.seekg(0, std::fstream::beg);

        str = new char[size+1];
        if(!str)
        {
            f.close();
            return NULL;
        }

        f.read(str, fileSize);
        f.close();
        str[size] = '\0';
    
        s = str;
        delete[] str;
        return s;
    }
    else
    {
        std::cout << "\nFile containg the kernel code(\".cl\") not found. Please copy the required file in the folder containg the executable.\n";
        exit(1);
    }
    return NULL;
}

/*
 * \brief OpenCL related initialization 
 *        Create Context, Device list, Command Queue
 *        Create OpenCL memory buffer objects
 *        Load CL file, compile, link CL source 
 *		  Build program and kernel objects
 */
int
initializeCL(void)
{
    cl_int status = 0;
    size_t deviceListSize;
//	sampleCommon = new streamsdk::SDKCommon();
    /*
     * Have a look at the available platforms and pick either
     * the AMD one if available or a reasonable default.
     */

    cl_uint numPlatforms;
    cl_platform_id platform = NULL;
    status = clGetPlatformIDs(0, NULL, &numPlatforms);
    if(status != CL_SUCCESS)
    {
        std::cout << "Error: Getting Platforms. (clGetPlatformsIDs)\n";
        return 1;
    }
    
    if(numPlatforms > 0)
    {
        cl_platform_id* platforms = new cl_platform_id[numPlatforms];
        status = clGetPlatformIDs(numPlatforms, platforms, NULL);
        if(status != CL_SUCCESS)
        {
            std::cout << "Error: Getting Platform Ids. (clGetPlatformsIDs)\n";
            return 1;
        }
        for(unsigned int i=0; i < numPlatforms; ++i)
        {
            char pbuff[100];
            status = clGetPlatformInfo(
                        platforms[i],
                        CL_PLATFORM_VENDOR,
                        sizeof(pbuff),
                        pbuff,
                        NULL);
            if(status != CL_SUCCESS)
            {
                std::cout << "Error: Getting Platform Info.(clGetPlatformInfo)\n";
                return 1;
            }
            platform = platforms[i];
			std::cout << "Device" << i << " = " << pbuff << std::endl;
            if(!strcmp(pbuff, "Advanced Micro Devices, Inc."))
            {
                break;
            }
        }
        delete platforms;
    }

    if(NULL == platform)
    {
        std::cout << "NULL platform found so Exiting Application." << std::endl;
        return 1;
    }

    /*
     * If we could find our platform, use it. Otherwise use just available platform.
     */
    cl_context_properties cps[3] = { CL_CONTEXT_PLATFORM, (cl_context_properties)platform, 0 };

    /////////////////////////////////////////////////////////////////
    // Create an OpenCL context
    /////////////////////////////////////////////////////////////////
	cl_device_type type;
	cpu == true ? type = CL_DEVICE_TYPE_CPU : type = CL_DEVICE_TYPE_GPU;
    context = clCreateContextFromType(cps, 
                                      type, 
                                      NULL, 
                                      NULL, 
                                      &status);
    if(status != CL_SUCCESS) 
    {  
        std::cout<<"Error: Creating Context. (clCreateContextFromType)\n";
        return 1; 
    }

    /* First, get the size of device list data */
    status = clGetContextInfo(context, 
                              CL_CONTEXT_DEVICES, 
                              0, 
                              NULL, 
                              &deviceListSize);
    if(status != CL_SUCCESS) 
    {  
        std::cout<<
            "Error: Getting Context Info \
            (device list size, clGetContextInfo)\n";
        return 1;
    }

    /////////////////////////////////////////////////////////////////
    // Detect OpenCL devices
    /////////////////////////////////////////////////////////////////
    devices = (cl_device_id *)malloc(deviceListSize);
    if(devices == 0)
    {
        std::cout<<"Error: No devices found.\n";
        return 1;
    }

    /* Now, get the device list data */
    status = clGetContextInfo(
                 context, 
                 CL_CONTEXT_DEVICES, 
                 deviceListSize, 
                 devices, 
                 NULL);
    if(status != CL_SUCCESS) 
    { 
        std::cout<<
            "Error: Getting Context Info \
            (device list, clGetContextInfo)\n";
        return 1;
    }

    /////////////////////////////////////////////////////////////////
    // Create an OpenCL command queue
    /////////////////////////////////////////////////////////////////
    commandQueue = clCreateCommandQueue(
                       context, 
                       devices[0], 
                       CL_QUEUE_PROFILING_ENABLE, 
                       &status);
    if(status != CL_SUCCESS) 
    { 
        std::cout<<"Creating Command Queue. (clCreateCommandQueue)\n";
        return 1;
    }

    /////////////////////////////////////////////////////////////////
    // Create OpenCL memory buffers
    /////////////////////////////////////////////////////////////////
    inputBufferA = clCreateBuffer(
                      context, 
                      CL_MEM_READ_WRITE | CL_MEM_USE_HOST_PTR,
                      sizeof(cl_double) * width,
                      inputA, 
                      &status);
    if(status != CL_SUCCESS) 
    { 
        std::cout<<"Error: clCreateBuffer (inputBufferA)\n";
        return 1;
    }

	inputBufferB = clCreateBuffer(
                      context, 
                      CL_MEM_READ_WRITE | CL_MEM_USE_HOST_PTR,
                      sizeof(cl_double) * width,
                      inputB, 
                      &status);
    if(status != CL_SUCCESS) 
    { 
        std::cout<<"Error: clCreateBuffer (inputBufferB)\n";
        return 1;
    }

    outputBufferC = clCreateBuffer(
                       context, 
                       CL_MEM_READ_WRITE | CL_MEM_USE_HOST_PTR,
                       sizeof(cl_double) * width,
                       outputC, 
                       &status);
    if(status != CL_SUCCESS) 
    { 
        std::cout<<"Error: clCreateBuffer (outputBufferC)\n";
        return 1;
    }


    /////////////////////////////////////////////////////////////////
    // Load CL file, build CL program object, create CL kernel object
    /////////////////////////////////////////////////////////////////
    const char * filename  = "CPUVsGPUTest_Kernels.cl";
    std::string  sourceStr = convertToString(filename);
    const char * source    = sourceStr.c_str();
    size_t sourceSize[]    = { strlen(source) };

    program = clCreateProgramWithSource(
                  context, 
                  1, 
                  &source,
                  sourceSize,
                  &status);
    if(status != CL_SUCCESS) 
    { 
      std::cout<<
               "Error: Loading Binary into cl_program \
               (clCreateProgramWithBinary)\n";
      return 1;
    }

    /* create a cl program executable for all the devices specified */
    status = clBuildProgram(program, 1, devices, NULL, NULL, NULL);
    if(status != CL_SUCCESS) 
    { 
        std::cout<<"Error: Building Program (clBuildProgram)\n";
        return 1; 
    }

    /* get a kernel object handle for a kernel with the given name */
    kernel = clCreateKernel(program, "CPUvsGPUTestKernel", &status);
    if(status != CL_SUCCESS) 
    {  
        std::cout<<"Error: Creating Kernel from program. (clCreateKernel)\n";
        return 1;
    }

    return 0;
}


/*
 * \brief Run OpenCL program 
 *		  
 *        Bind host variables to kernel arguments 
 *		  Run the CL kernel
 */
int 
runCLKernels(void)
{
    cl_int   status;
    cl_uint maxDims;
    cl_event events[2];
    size_t globalThreads[1];
    size_t localThreads[1];
    size_t maxWorkGroupSize;
    size_t maxWorkItemSizes[3];

    /**
    * Query device capabilities. Maximum 
    * work item dimensions and the maximmum
    * work item sizes
    */ 
    status = clGetDeviceInfo(
        devices[0], 
        CL_DEVICE_MAX_WORK_GROUP_SIZE, 
        sizeof(size_t), 
        (void*)&maxWorkGroupSize, 
        NULL);
    if(status != CL_SUCCESS) 
    {  
        std::cout<<"Error: Getting Device Info. (clGetDeviceInfo)\n";
        return 1;
    }
    
    status = clGetDeviceInfo(
        devices[0], 
        CL_DEVICE_MAX_WORK_ITEM_DIMENSIONS, 
        sizeof(cl_uint), 
        (void*)&maxDims, 
        NULL);
    if(status != CL_SUCCESS) 
    {  
        std::cout<<"Error: Getting Device Info. (clGetDeviceInfo)\n";
        return 1;
    }

    status = clGetDeviceInfo(
        devices[0], 
        CL_DEVICE_MAX_WORK_ITEM_SIZES, 
        sizeof(size_t)*maxDims,
        (void*)maxWorkItemSizes,
        NULL);
    if(status != CL_SUCCESS) 
    {  
        std::cout<<"Error: Getting Device Info. (clGetDeviceInfo)\n";
        return 1;
    }
    
    globalThreads[0] = width;
    localThreads[0]  = 256;

	std::cout << "Max dimensions: " << maxDims << std::endl;
	std::cout << "Device maxWorkGroupSize = " << maxWorkGroupSize << std::endl;
	std::cout << "Device maxWorkItemSizes = " << maxWorkItemSizes[0] << std::endl;
    if(localThreads[0] > maxWorkGroupSize ||
        localThreads[0] > maxWorkItemSizes[0])
    {
        std::cout<<"Unsupported: Device does not support requested number of work items.";
        return 1;
    }

    /*** Set appropriate arguments to the kernel ***/
    /* the output array to the kernel */
    status = clSetKernelArg(
                    kernel, 
                    0, 
                    sizeof(cl_mem), 
                    (void *)&outputBufferC);
    if(status != CL_SUCCESS) 
    { 
        std::cout<<"Error: Setting kernel argument. (output)\n";
        return 1;
    }

    /* the input array A to the kernel */
    status = clSetKernelArg(
                    kernel, 
                    1, 
                    sizeof(cl_mem), 
                    (void *)&inputBufferA);
    if(status != CL_SUCCESS) 
    { 
        std::cout<<"Error: Setting kernel argument. (input)\n";
        return 1;
    }

    /* the input array B to the kernel*/
    status = clSetKernelArg(
                    kernel, 
                    2, 
                    sizeof(cl_mem), 
                    (void *)&inputBufferB);
    if(status != CL_SUCCESS) 
    { 
        std::cout<< "Error: Setting kernel argument. (multiplier)\n";
        return 1;
    }
	cl_ulong startTime, endTime;
    /* 
     * Enqueue a kernel run call.
     */
    status = clEnqueueNDRangeKernel(
                 commandQueue,
                 kernel,
                 1,
                 NULL,
                 globalThreads,
                 localThreads,
                 0,
                 NULL,
                 &events[0]);
    if(status != CL_SUCCESS) 
    { 
        std::cout<<
            "Error: Enqueueing kernel onto command queue. \
            (clEnqueueNDRangeKernel)\n";
        return 1;
    }


    /* wait for the kernel call to finish execution */
    status = clWaitForEvents(1, &events[0]);
    if(status != CL_SUCCESS) 
    { 
        std::cout<<
            "Error: Waiting for kernel run to finish. \
            (clWaitForEvents)\n";
        return 1;
    }

	clGetEventProfilingInfo(events[0], CL_PROFILING_COMMAND_START,
	sizeof(cl_ulong), &startTime, NULL);
	clGetEventProfilingInfo(events[0], CL_PROFILING_COMMAND_END,
	sizeof(cl_ulong), &endTime, NULL);
	cl_ulong kernelExecTimeNs = 1e-6*(endTime-startTime);
	std::cout << "kernel execution time = " << kernelExecTimeNs << "ms." << std::endl;

    status = clReleaseEvent(events[0]);
    if(status != CL_SUCCESS) 
    { 
        std::cout<<
            "Error: Release event object. \
            (clReleaseEvent)\n";
        return 1;
    }

    /* Enqueue readBuffer*/
    status = clEnqueueReadBuffer(
                commandQueue,
                outputBufferC,
                CL_TRUE,
                0,
                width * sizeof(cl_uint),
                outputC,
                0,
                NULL,
                &events[1]);
    
    if(status != CL_SUCCESS) 
    { 
        std::cout << 
            "Error: clEnqueueReadBuffer failed. \
             (clEnqueueReadBuffer)\n";

        return 1;
    }
    
    /* Wait for the read buffer to finish execution */
    status = clWaitForEvents(1, &events[1]);
    if(status != CL_SUCCESS) 
    { 
        std::cout<<
            "Error: Waiting for read buffer call to finish. \
            (clWaitForEvents)\n";
        return 1;
    }
    
    status = clReleaseEvent(events[1]);
    if(status != CL_SUCCESS) 
    { 
        std::cout<<
            "Error: Release event object. \
            (clReleaseEvent)\n";
        return 1;
    }

    return 0;
}


/*
 * \brief Release OpenCL resources (Context, Memory etc.) 
 */
int  
cleanupCL(void)
{
    cl_int status;

    status = clReleaseKernel(kernel);
    if(status != CL_SUCCESS)
    {
        std::cout<<"Error: In clReleaseKernel \n";
        return 1; 
    }
    status = clReleaseProgram(program);
    if(status != CL_SUCCESS)
    {
        std::cout<<"Error: In clReleaseProgram\n";
        return 1; 
    }
    status = clReleaseMemObject(inputBufferA);
    if(status != CL_SUCCESS)
    {
        std::cout<<"Error: In clReleaseMemObject (inputBufferA)\n";
        return 1; 
    }
	status = clReleaseMemObject(inputBufferB);
    if(status != CL_SUCCESS)
    {
        std::cout<<"Error: In clReleaseMemObject (inputBufferB)\n";
        return 1; 
    }
    status = clReleaseMemObject(outputBufferC);
    if(status != CL_SUCCESS)
    {
        std::cout<<"Error: In clReleaseMemObject (outputBuffer)\n";
        return 1; 
    }
    status = clReleaseCommandQueue(commandQueue);
    if(status != CL_SUCCESS)
    {
        std::cout<<"Error: In clReleaseCommandQueue\n";
        return 1;
    }
    status = clReleaseContext(context);
    if(status != CL_SUCCESS)
    {
        std::cout<<"Error: In clReleaseContext\n";
        return 1;
    }

    return 0;
}


/* 
 * \brief Releases program's resources 
 */
void
cleanupHost(void)
{
    if(inputA != NULL)
    {
        free(inputA);
        inputA = NULL;
    }
	if(inputB != NULL)
    {
        free(inputB);
        inputB = NULL;
    }
    if(outputC != NULL)
    {
        free(outputC);
        outputC = NULL;
    }
    if(devices != NULL)
    {
        free(devices);
        devices = NULL;
    }
}


/*
 * \brief Print no more than 256 elements of the given array.
 *
 *        Print Array name followed by elements.
 */
void print1DArray(
         const std::string arrayName, 
         const unsigned int * arrayData, 
         const unsigned int length)
{
    cl_uint i;
    cl_uint numElementsToPrint = (256 < length) ? 256 : length;

    std::cout << std::endl;
    std::cout << arrayName << ":" << std::endl;
    for(i = 0; i < numElementsToPrint; ++i)
    {
        std::cout << arrayData[i] << " ";
    }
    std::cout << std::endl;

}

void verify()
{
    bool passed = true;
    for(unsigned int i = 0; i < width; ++i)
        if(inputA[i] * inputB[i] != outputC[i])
            passed = false;

    if(passed == true)
        std::cout << "Passed!\n" << std::endl;
    else
        std::cout << "Failed!\n" << std::endl;
}

int 
main(int argc, char * argv[])
{
    // Initialize Host application 
    if(initializeHost()==1)
        return 1;

    // Initialize OpenCL resources
    if(initializeCL()==1)
        return 1;

	//int timer = sampleCommon->createTimer();
    //sampleCommon->resetTimer(timer);
    //sampleCommon->startTimer(timer);

    // Run the CL program
    if(runCLKernels()==1)
        return 1;

	//sampleCommon->stopTimer(timer);
    //double totalKernelTime = (double)(sampleCommon->readTimer(timer));

	
    // Print output array
    //print1DArray(std::string("Output"), outputC, width);

    // Verify output
    verify();

    // Releases OpenCL resources 
    if(cleanupCL()==1)
        return 1;

    // Release host resources
    cleanupHost();

    return 0;
}
