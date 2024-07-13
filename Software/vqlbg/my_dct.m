% �����ź�����
x = [1, 2, 3, 4, 5, 6, 7, 8,1, 2, 3, 4, 5, 6, 7, 8,1, 2, 3, 4, 5, 6, 7, 8,1, 2, 3, 4, 5, 6, 7];
% �����źŵĳ���
N = length(x);

% ��ʼ���������
X = zeros(1, N);

% ���� DCT ϵ�� 
for k = 0:N-1
    sum_val = 0;
    if k==0
        a = sqrt(1/N);
    else 
        a = sqrt(2/N);
    end
    for n = 0:N-1
        sum_val = sum_val + x(n+1) * cos(pi/N * (n + 0.5) * k)*a;
    end
    X(k+1) = sum_val;
end
% ��ʼ���������
y = zeros(N, N);
%����dctϡ��
for k = 0:N-1
    sum_val = 0;
    if k==0
        a = sqrt(1/N);
    else 
        a = sqrt(2/N);
    end
    for n = 0:N-1
        y(k+1,n+1) =   cos(pi/N * (n + 0.5) * k)*a;
    end

end
row_sums = sum(y .* (y > 0), 2);
    y1 = sum(y, 2);

result = reshape(y.', [], 1);
result1 = round(result *255);


% ���ԭ������Ԫ��Ϊ��������ת����Ķ������ַ���ǰ����ϸ���
result2 = strings(length(result1), 1); % ��ʼ�� result2��ȷ����С�� result1 ��ͬ
for i = 1:length(result1)
     result2(i) = twos_complement(result1(i), 9);
end

function complement = twos_complement(num, bits)
    % num: Ҫת����ʮ������
    % bits: ����λ��
    
    % �����Ĳ������
    if num < 0
        % ��ȡ num �Ķ����Ʊ�ʾ��ʽ
        binary_num = dec2bin(abs(num), bits);
        
        % ȡ��
        inverted_binary_num = 1 - (binary_num - '0');

        
        % �� 1
        binary_sum = bin2dec(num2str(inverted_binary_num)) + 1;
        binary_sum = dec2bin(binary_sum, bits);

        complement = binary_sum;
    else
        % �����Ĳ���Ϊ�䱾��
        complement =  dec2bin(abs(num), bits);
    end
end
