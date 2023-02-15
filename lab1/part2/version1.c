#include <stdio.h>
#include <pthread.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>

int main()
{
	pthread_t f2_thread, f1_thread;
	void *f1();
	int i1 = 1;
	pthread_create(&f1_thread, NULL, f1, &i1);
	pthread_join(f1_thread, NULL);
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
