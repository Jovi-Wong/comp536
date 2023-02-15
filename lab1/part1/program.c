#include <stdio.h>
#include <pthread.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>

int main()
{
	pthread_t f2_thread, f1_thread;
	void *f2(), *f1();
	int i1, i2;
	i1 = 1;
	i2 = 2;
	pthread_create(&f1_thread, NULL, f1, &i1);
	pthread_create(&f2_thread, NULL, f2, &i2);
	pthread_join(f1_thread, NULL);
	pthread_join(f2_thread, NULL);
}

/*thread for the library call version*/
void *f1(int *x)
{
	long i;
	FILE *fp;
	if ((fp=fopen("fprint.out","w")) == NULL) {
		fprintf(stderr,"Can't open fprint.out.  Bye.\n");
		pthread_exit(NULL);
	}
	for (i=0; i<300000; i++) {  /* write 300,000 Xs with fprintf */
		if (fprintf(fp,"X") < 1) {
			fprintf(stderr,"Can't write. Bye\n");
			pthread_exit(NULL);
		}
	}
	fclose(fp);

	printf("f1\n");
	pthread_exit(NULL);
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

