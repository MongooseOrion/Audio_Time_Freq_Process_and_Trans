% 定义信号向量
x = [1, 2, 3, 4, 5, 6, 7, 8,1, 2, 3, 4, 5, 6, 7, 8,1, 2, 3, 4, 5, 6, 7, 8,1, 2, 3, 4, 5, 6, 7];
% 输入信号的长度
N = length(x);

% 初始化输出向量
X = zeros(1, N);

% 计算 DCT 系数 
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
% 初始化输出向量
y = zeros(N, N);
%导出dct稀疏
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


% 如果原数组中元素为负数，则将转换后的二进制字符串前面加上负号
result2 = strings(length(result1), 1); % 初始化 result2，确保大小与 result1 相同
for i = 1:length(result1)
     result2(i) = twos_complement(result1(i), 9);
end

function complement = twos_complement(num, bits)
    % num: 要转换的十进制数
    % bits: 补码位数
    
    % 负数的补码计算
    if num < 0
        % 获取 num 的二进制表示形式
        binary_num = dec2bin(abs(num), bits);
        
        % 取反
        inverted_binary_num = 1 - (binary_num - '0');

        
        % 加 1
        binary_sum = bin2dec(num2str(inverted_binary_num)) + 1;
        binary_sum = dec2bin(binary_sum, bits);

        complement = binary_sum;
    else
        % 正数的补码为其本身
        complement =  dec2bin(abs(num), bits);
    end
end
