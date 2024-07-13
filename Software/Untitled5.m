% 生成一个简单的数组
signal = [1, 2, 3, -4, 5, -6, 7, -8, 9, -10];

% 计算过零率
zeroCrossings = nnz(diff(signal > 0) ~= 0); % 计算信号中符号变化的次数
zeroCrossRate = zeroCrossings / length(signal); % 计算过零率

disp(['过零率为：', num2str(zeroCrossRate)]);
