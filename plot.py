import csv
import matplotlib.pyplot as plt
import numpy as np

with open('training_accuracy.txt', newline='') as f:
    reader = csv.reader(f)
    training_data = list(reader)

with open('test_accuracy.txt', newline='') as f:
    reader = csv.reader(f)
    test_data = list(reader)

print(test_data)
print(training_data)
plt.plot(np.arange(0, np.size(training_data)), training_data[0], label="training_error")
plt.plot(np.arange(0, np.size(test_data)), test_data[0], label="test_error")
plt.legend()
plt.ylabel("accuracy")
plt.xlabel("rate")
plt.title("K_means")
plt.show(block=True)
exit(0)