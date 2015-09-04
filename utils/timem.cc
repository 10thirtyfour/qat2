#include <windows.h>                      
#include <stdio.h>
#include <tchar.h>
#include <psapi.h>


void PrintMemoryAndTimeInfo (DWORD processID)
{
    HANDLE hProcess;
    DWORD ExitCode=-1;
    PROCESS_MEMORY_COUNTERS pmc;
    FILETIME CreationTime;
    FILETIME ExitTime;
    FILETIME KernelTime;
    FILETIME UserTime;
    ULONGLONG ctime=0;
    ULONGLONG etime=0;
    ULONGLONG ktime=0;
    ULONGLONG utime=0;
    ULONGLONG ptime=0;
    ZeroMemory(&pmc, sizeof(PROCESS_MEMORY_COUNTERS));

    // Get a handle for the process
    hProcess = OpenProcess(PROCESS_QUERY_INFORMATION | PROCESS_VM_READ | SYNCHRONIZE ,
                           FALSE, processID);

    fprintf(stdout, "{\n");


    if (NULL == hProcess) {
        fprintf(stdout, "}\n");
        fprintf(stderr, " OpenProcess() returned NULL\n");
        return;
    }




    WaitForSingleObject( hProcess , INFINITE);



    if (GetProcessTimes(hProcess, &CreationTime, &ExitTime,
                        &KernelTime, &UserTime)) {
        //LPSYSTEMTIME t;
        //FileTimeToSystemTime(&CreationTime, t);

        ctime = (((ULONGLONG) CreationTime.dwHighDateTime << 32)
                        + (ULONGLONG) CreationTime.dwLowDateTime);
        etime = (((ULONGLONG) ExitTime.dwHighDateTime << 32)
                        + (ULONGLONG) ExitTime.dwLowDateTime);
        ktime = (((ULONGLONG) KernelTime.dwHighDateTime << 32)
                        + (ULONGLONG) KernelTime.dwLowDateTime);
        utime = (((ULONGLONG) UserTime.dwHighDateTime << 32)
                        + (ULONGLONG) UserTime.dwLowDateTime);
        if(etime>0) {
          ptime=etime-ctime;
        }
    }

    fprintf(stdout, "   \"pid\" : \"%d\",\n",processID);

    fprintf(stdout, "  \"CreationTime\" : \"%u\",\n", ctime / 10000 - 11644473600000);
    fprintf(stdout, "  \"ExitTime\"     : \"%u\",\n", etime / 10000 - 11644473600000);
    fprintf(stdout, "  \"KernelTime\"   : \"%u\",\n", ktime);
    fprintf(stdout, "  \"UserTime\"     : \"%u\",\n", utime);
    fprintf(stdout, "  \"ElapsedTime\"  : \"%u\",\n", ptime / 10000);

    GetProcessMemoryInfo(hProcess, &pmc, sizeof(pmc));
    fprintf(stdout, "  \"PageFaultCount\" : \"%d\",\n", pmc.PageFaultCount);
    fprintf(stdout, "  \"PeakWorkingSetSize\" : \"%d\",\n", pmc.PeakWorkingSetSize);
    fprintf(stdout, "  \"QuotaPeakPagedPoolUsage\" : \"%d\",\n", pmc.QuotaPeakPagedPoolUsage);
    fprintf(stdout, "  \"QuotaPeakNonPagedPoolUsage\" : \"%d\",\n", pmc.QuotaPeakNonPagedPoolUsage);
    fprintf(stdout, "  \"PeakPagefileUsage\" : \"%d\",\n", pmc.PeakPagefileUsage);

    GetExitCodeProcess(hProcess, &ExitCode);
    fprintf(stdout, "  \"ExitCode\" : \"%d\"\n", ExitCode);

    fprintf(stdout, "}\n");
    CloseHandle(hProcess);
}


void _tmain (int argc, TCHAR *argv[])
{
    if(argc!=2) {
      fprintf(stdout, "usage : timem.exe #pid\n");
      return;
    }
    PrintMemoryAndTimeInfo( strtol(argv[1],0, 0));
}
