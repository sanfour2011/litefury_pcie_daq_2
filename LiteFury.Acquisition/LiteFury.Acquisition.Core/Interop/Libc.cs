using System;
using System.Runtime.InteropServices;

namespace LiteFury.Acquisition.Core.Interop;

public static class Libc
{
    // fcntl.h (https://github.com/torvalds/linux/blob/master/include/uapi/asm-generic/fcntl.h)
    public const int O_RDONLY = 0;
    public const int O_WRONLY = (1 << 0);
    public const int O_RDWR = (1 << 1);
    public const int O_SYNC = (1 << 20);

    // mman.h (https://github.com/torvalds/linux/blob/1b78070aaef63512688aebfbc82365ef9d6660f1/tools/arch/mips/include/uapi/asm/mman.h)
    public const int PROT_READ = 0x1;
    public const int PROT_WRITE = 0x2;

    public const int MAP_SHARED = 0x01;

    public static readonly IntPtr MAP_FAILED = new(-1);

    [DllImport("libc", SetLastError = true)]
    public static extern int open([MarshalAs(UnmanagedType.LPStr)] string pathname, int flags);

    [DllImport("libc", SetLastError = true)]
    public static extern int close(int fd);

    [DllImport("libc", SetLastError = true)]
    public static extern IntPtr mmap(IntPtr addr, UIntPtr length, int prot, int flags, int fd, long offset);

    [DllImport("libc", SetLastError = true)]
    public static extern int munmap(IntPtr addr, UIntPtr length);

    [DllImport("libc", SetLastError = true)]
    public static extern IntPtr pread(int fd, IntPtr buf, UIntPtr count, long offset);

    [DllImport("libc", SetLastError = true)]
    public static extern int read(int fd, out int buf, UIntPtr count);
}