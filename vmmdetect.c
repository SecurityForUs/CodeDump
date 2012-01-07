/*
 * Code is derived from different sources:
 *
 * ScoopyNG Homepage (OSS): http://trapkit.de/
 *    Website has referer checking so direct link to the software will give you a 404
 * SANS
 *    http://handlers.sans.org/tliston/ThwartingVMDetection_Liston_Skoudis.pdf
 *
 * Tested Machines:
 * -- Windows Host
 * ---- VMware Workstation 7.x, Windows 7 Host, Ubuntu 11.04 32-bit Guest
 * -- Linux Host
 * ---- ArchLinux Host
 * ---- Ubuntu 11.04 32-bit Host
 *
 * Most code does not detect the VM correctly anymore, except for the port check on tests I've ran.
 *
 * Source is available for free.  I'm not responsible for any harm this might do.
 * If any questions arise, please contact me at ehansen@securityfor.us and I'll do my best to assist.
 *
 * If enough interest is given, I will port this to Windows and/or strictly assembly-based in the future.
 **/
#include <stdio.h>
#include <sys/io.h>
#include <errno.h>
#include <string.h>

static const char *VMM = "Virtual Machine (VMM)";
static const char *HOS = "Host Machine";
static int is_vm = 1; // 1 = Yes, 0 = No

void VMIDT(void){
    unsigned char idtr[6];
    unsigned long idt = 0;

    __asm__ __volatile__("sidt %0":"=m"(idtr));

    idt = *((unsigned long*)&idtr[2]);
    printf("IDT Base:\t0x%x\n", idt);

    idt = idt >> 24;
    printf("IDT Byte check:\t0x%x\nResults:\t", idt);

    if(idt == 0xff)
        printf("%s\n", VMM);
    else{
        printf("Host Machine\nProbing OS:\t");
        if(idt >= 0xc0 && idt <= 0xd0)
            printf("Linux\n");
        else if(idt >= 0xd0 && idt <= 0xe0)
            printf("Windows\n");

	is_vm = 0;
    }
}

void VMLDTR(void){
    unsigned char ldtr[5] = "\xef\xbe\xad\xde";
    unsigned long ldt = 0;

    __asm__ __volatile__("sldt %0":"=m"(ldtr));
    ldt = *((unsigned long*)&ldtr[0]);
    printf("LDTR Base:\t0x%x\nResults:\t", ldt);

    if(ldt == 0xdead0000){
        printf("%s\n", HOS);

	is_vm = 0;
    } else
        printf("%s\n", VMM);
}

void VMS21SEC(void){
    unsigned char mem[4] = {0,0,0,0};

    __asm__("str %0":"=m"(mem));

    printf("Results:\t");

    if((mem[0]==0x00) && (mem[1]==0x40))
        printf("%s\n", VMM);
    else
        printf("%s\n", HOS);
}

void VMPORT(void){
    char name[255] = {'\0'};
    FILE *namep = popen("whoami", "r");
    fgets(name, sizeof(name), namep);
    pclose(namep);

    if(name != "root"){
	printf("You need to be root %s.", name);
	return;
    } else{
        printf("You are root.");
    }

    if(!is_vm){
	printf("!! Previous tests ran are showing this to be a host OS.\n!! However, this test will check a special communications port.\n\n");
    }

    /**
     * iopl() is used to allowe privileged access to ports above 0x3ff (we need 0x56...).
     * Unfortunately, iopl() requires root access due to how it works.  This function
     * shouldn't return anything besides 0 if you're root(ish).
    **/
    int io = iopl(3);

    int err = errno;

    if(err != 0){
	    printf("io returned = %d (errno = %d; %s)\n", io, err, strerror(err));
    }
/*
    WIP but used to open up the port we need.

    io = ioperm(0x564d5868, 4, 4);

    err = errno;

    if(err != 0){
	    printf("io returned = %d (errno = %d; %s)\n", io, err, strerror(err));
	    printf("!! Make sure you run this program as root (or another super-privileged user)\n\n");
    }
*/
    unsigned int a, b;

    /** We want to preserve the stack, try to connect to port 0x564d5868 and get the version information (0x0A),
        and then restore the stack back to what it was. **/
    __asm__ __volatile__("pushl %%eax\n"
        "pushl %%ebx\n"
        "pushl %%ecx\n"
        "pushl %%edx\n"
        "mov $0x564d5868,%%eax\n"
        "xor $0,%%ebx\n"
        "mov $0x0a,%%ecx\n"
        "mov $0x5658,%%dx\n"
        "in %%dx,%%eax" : "=b"(a), "=c"(b));
    __asm__ __volatile__("popl %edx\n"
        "popl %ecx\n"
        "popl %ebx\n"
        "popl %eax");

    printf("Address:\t0x%x\nType Code:\t%d\nResults:\t",a,b);

    if(a == 'VMXh'){
        printf("%s\n", VMM);

        printf("Type:\t");

        switch(b){
            case 1:
                printf("Express");
                break;
            case 2:
                printf("ESX");
                break;
            case 3:
                printf("GSX");
                break;
            case 4:
                printf("Workstation");
                break;
            default:
                printf("Unknown");
                break;
        }
    } else{
        printf("%s\n",HOS);
    }
}

int main()
{
    printf("While tests 1 & 2 would work back in 2006, when this technique was first released, they are not reliable anymore.  Test 3 is the most accurate as it tries to talk to the VME itself.  If it segfaults, then\n\n");

    printf("-----\tTest #1: IDTR\t-----\n");
    VMIDT();

    printf("\n-----\tTest #2: LDTR\t-----\n");
    VMLDTR();

    printf("\n-----\tTest #3: VME\t-----\n");
    VMPORT();

    printf("\n-----\tTest #4: S21SEC\t-----\n");
    VMS21SEC();

    return 0;
}
