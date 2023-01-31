from matplotlib import pyplot as plt
import numpy as np

# t1 = []
# with open("ver1_time.txt", "r") as file:
#     for line in file.readlines():
#         t1.append(float(line.split()[2][3:7]))

# t2 = []
# with open("ver2_time.txt", "r") as file:
#     for line in file.readlines():
#         t2.append(float(line.split()[2][3:7]))

# n1, bin1 = np.histogram(t1, [0.0, 0.01, 0.02, 0.03, 0.04, 0.05], density=True)
# n2, bin2 = np.histogram(t2, [0.10,0.11,0.12,0.13,0.14,0.15,0.16,0.17,0.18,0.19,0.2], density=True)

# x1 = bin1[0:-1]
# x2 = bin2[0:-1]
# y1 = np.cumsum(n1 / sum(n1))
# y2 = np.cumsum(n2 / sum(n2))

# fig, ax = plt.subplots()
# ax.plot(x1, y1, label = "version1")
# ax.plot(x2, y2, label = "version2")
# ax.set_xlabel("execution time")
# ax.set_ylabel("ratio")
# ax.set_title("CDF curve of two programs")
# plt.legend()
# plt.show()

t1_user = []
t1_kernel = []
with open("ver1_time.txt", "r") as file:
    for line in file.readlines():
        t1_user.append(float(line.split()[0][0:4]))
        t1_kernel.append(float(line.split()[1][0:4]))

t2_user = []
t2_kernel = []
with open("ver2_time.txt", "r") as file:
    for line in file.readlines():
        t2_user.append(float(line.split()[0][0:4]))
        t2_kernel.append(float(line.split()[1][0:4]))

# un1, ubin1 = np.histogram(t1_user, [0.00, 0.01, 0.02], density=True)
# un2, ubin2 = np.histogram(t2_user, [0.01, 0.02, 0.03, 0.04,0.05], density=True)

# x1 = ubin1[0:-1]
# x2 = ubin2[0:-1]
# y1 = np.cumsum(un1 / sum(un1))
# y2 = np.cumsum(un2 / sum(un2))

# fig, ax = plt.subplots()
# ax.plot(x1, y1, label = "version1")
# ax.plot(x2, y2, label = "version2")
# ax.set_xlabel("execution time")
# ax.set_ylabel("ratio")
# ax.set_title("CDF curve of two programs in the user mode")
# plt.legend()
# plt.show()

kn1, kbin1 = np.histogram(t1_kernel, [0.00, 0.01, 0.02], density=True)
kn2, kbin2 = np.histogram(t2_kernel, [0.06, 0.07, 0.08, 0.09, 0.10], density=True)

x1 = kbin1[0:-1]
x2 = kbin2[0:-1]
y1 = np.cumsum(kn1 / sum(kn1))
y2 = np.cumsum(kn2 / sum(kn2))
fig, ax = plt.subplots()
ax.plot(x1, y1, label = "version1")
ax.plot(x2, y2, label = "version2")
ax.set_xlabel("execution time")
ax.set_ylabel("ratio")
ax.set_title("CDF curve of two programs in the kernel mode")
plt.legend()
plt.show()