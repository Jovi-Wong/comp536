#include <stdio.h>
#include <pthread.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>

int main()
{
	pthread_t f2_thread, f1_thread;
	void *f2();
	int i2;
	i2 = 2;
	pthread_create(&f2_thread, NULL, f2, &i2);
	pthread_join(f2_thread, NULL);
}

void *f2(int *x)
{
	long i;
	int fd;

	if ((fd=open("write.out",O_WRONLY|O_CREAT,0644)) <  0) {
		fprintf(stderr,"Can't open write.out.  Bye.\n");
		pthread_exit(NULL);
	}
	for (i=0; i<100000; i++)  { /* write 100,000 Ys with write */
		if (write(fd,"Y",1) < 1) {
			fprintf(stderr,"Can't write. Bye\n");
			pthread_exit(NULL);
		}
	}
	close(fd);

	printf("f2\n");
	pthread_exit(NULL);
}

