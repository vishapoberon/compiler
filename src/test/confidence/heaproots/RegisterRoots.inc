/* Pin the only live root to each general-purpose callee-saved register.
   Callback addresses are not heap roots; scrub dead allocator stack slots. */
#if (defined(__GNUC__) || defined(__clang__)) && (defined(__x86_64__) || defined(__aarch64__))
static __attribute__((noinline)) void GCRegisterRoots_Scrub(void)
{
    volatile ADDRESS scratch[256];
    for (int i = 0; i < 256; ++i) scratch[i] = 0;
}

#define GC_REGISTER_TEST(name, reg) \
static __attribute__((noinline)) INTEGER name(ADDRESS (*make)(void), \
    void (*collect)(void), INTEGER (*alive)(ADDRESS)) \
{ \
    register ADDRESS root __asm__(reg) = make(); \
    __asm__ volatile("" : "+r"(root)); \
    GCRegisterRoots_Scrub(); \
    collect(); \
    __asm__ volatile("" : "+r"(root)); \
    return alive(root); \
}

#if defined(__x86_64__)
GC_REGISTER_TEST(GCRegisterRoots_1, "rbx")
GC_REGISTER_TEST(GCRegisterRoots_2, "r12")
GC_REGISTER_TEST(GCRegisterRoots_3, "r13")
GC_REGISTER_TEST(GCRegisterRoots_4, "r14")
GC_REGISTER_TEST(GCRegisterRoots_5, "r15")
#else
GC_REGISTER_TEST(GCRegisterRoots_1, "x19")
GC_REGISTER_TEST(GCRegisterRoots_2, "x20")
GC_REGISTER_TEST(GCRegisterRoots_3, "x21")
GC_REGISTER_TEST(GCRegisterRoots_4, "x22")
GC_REGISTER_TEST(GCRegisterRoots_5, "x23")
#endif

static INTEGER GCRegisterRoots_Run(ADDRESS (*make)(void), void (*collect)(void),
                                  INTEGER (*alive)(ADDRESS))
{
    return GCRegisterRoots_1(make, collect, alive) &&
           GCRegisterRoots_2(make, collect, alive) &&
           GCRegisterRoots_3(make, collect, alive) &&
           GCRegisterRoots_4(make, collect, alive) &&
           GCRegisterRoots_5(make, collect, alive);
}
#undef GC_REGISTER_TEST
#else
/* The portable allocation-pressure test still runs on other targets. */
static INTEGER GCRegisterRoots_Run(ADDRESS (*make)(void), void (*collect)(void),
                                  INTEGER (*alive)(ADDRESS))
{
    (void)make; (void)collect; (void)alive;
    return 1;
}
#endif
