load('mfcc.mat','r');
r = floor(r);
r1 = r(:, 1:310);
r1 = reshape(r1, 31, 200); 

r2=vqlbg(floor(r1),8);

r2(isnan(r2)) = 0;
d = disteu(r1, r2);   
dist = sum(min(d,[],2));  %变换得到一个距离的量

[row, col] = size(r1); % 获取矩阵的行数和列数
B = reshape(r1, row * col, 1); % 将矩阵展开为列向量
% 如果原数组中元素为负数，则将转换后的二进制字符串前面加上负号
result2 = strings(length(B), 1); % 初始化 result2，确保大小与 result1 相同
for i = 1:length(B)
     result2(i) = twos_complement(B(i), 9);
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


