% ����һ���򵥵�����
signal = [1, 2, 3, -4, 5, -6, 7, -8, 9, -10];

% ���������
zeroCrossings = nnz(diff(signal > 0) ~= 0); % �����ź��з��ű仯�Ĵ���
zeroCrossRate = zeroCrossings / length(signal); % ���������

disp(['������Ϊ��', num2str(zeroCrossRate)]);
