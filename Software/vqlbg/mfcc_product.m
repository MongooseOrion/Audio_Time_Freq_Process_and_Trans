load('mfcc.mat','r');
r2 = floor(r);
% t=0;
% % 假设矩阵为 A
% r1 = r(:, 1:300);
% r = r1;
% e = 3/127;
% mfcc_test = floor(r);
% mean1 = fix(mean(mfcc_test,2));
% r = [mean1+floor(e*mean1),mean1-floor(e*mean1)];
% z = disteu(mfcc_test, r);
% [m,ind] = min(z, [], 2);
% 
% r(:, 1) = fix(mean(mfcc_test(:, find(ind == 1)), 2));%计算第一列码本
% x = disteu(mfcc_test(:, find(ind == 1)), r(:, 1));
% for q = 1:length(x)
%     t = t + x(q);
% end
% 
% r(:, 2) = fix(mean(mfcc_test(:, find(ind == 2)), 2));  %计算第二列码本
% x = disteu(mfcc_test(:, find(ind == 2)), r(:, 2));
% for q = 1:length(x)
%     t = t + x(q);
% end
% drp=t;   %存储一下值
% t=0;
% z = disteu(mfcc_test, r);
% [m,ind] = min(z, [], 2);
% 
% r(:, 1) = fix(mean(mfcc_test(:, find(ind == 1)), 2));%第二次计算第一列码本
% x = disteu(mfcc_test(:, find(ind == 1)), r(:, 1));
% for q = 1:length(x)
%     t = t + x(q);
% end
% 
% r(:, 2) = fix(mean(mfcc_test(:, find(ind == 2)), 2));  %第二次计算第二列码本
% x = disteu(mfcc_test(:, find(ind == 2)), r(:, 2));
% for q = 1:length(x)
%     t = t + x(q);
% end
% 
% if (((drp - t)/t) < e)
%     c=1;
% else
%     c=0;
% end
% 
% r = [r+floor(e*r),r-floor(e*r)];  %分裂成4列
% z = disteu(mfcc_test, r);
% [m,ind] = min(z, [], 2);
% t=0;
% r(:, 1) = fix(mean(mfcc_test(:, find(ind == 1)), 2));%计算第一列码本
% x = disteu(mfcc_test(:, find(ind == 1)), r(:, 1));
% for q = 1:length(x)
%     t = t + x(q);
% end
% 
% r(:, 2) = fix(mean(mfcc_test(:, find(ind == 2)), 2));%计算第一列码本
% x = disteu(mfcc_test(:, find(ind == 2)), r(:, 2));
% for q = 1:length(x)
%     t = t + x(q);
% end
% 
% r(:, 3) = fix(mean(mfcc_test(:, find(ind == 3)), 2));  %计算第二列码本
% x = disteu(mfcc_test(:, find(ind == 3)), r(:, 3));
% for q = 1:length(x)
%     t = t + x(q);
% end
% 
% r(:, 4) = fix(mean(mfcc_test(:, find(ind == 4)), 2));  %计算第二列码本
% x = disteu(mfcc_test(:, find(ind == 4)), r(:, 4));
% for q = 1:length(x)
%     t = t + x(q);
% end
% 
% 
% %第二次计算第二列
% drp=t;   %存储一下值
% t=0;
% z = disteu(mfcc_test, r);
% [m,ind] = min(z, [], 2);
% t=0;
% r(:, 1) = fix(mean(mfcc_test(:, find(ind == 1)), 2));%计算第一列码本
% x = disteu(mfcc_test(:, find(ind == 1)), r(:, 1));
% for q = 1:length(x)
%     t = t + x(q);
% end
% 
% r(:, 2) = fix(mean(mfcc_test(:, find(ind == 2)), 2));%计算第一列码本
% x = disteu(mfcc_test(:, find(ind == 2)), r(:, 2));
% for q = 1:length(x)
%     t = t + x(q);
% end
% 
% r(:, 3) = fix(mean(mfcc_test(:, find(ind == 3)), 2));  %计算第二列码本
% x = disteu(mfcc_test(:, find(ind == 3)), r(:, 3));
% for q = 1:length(x)
%     t = t + x(q);
% end
% 
% r(:, 4) = fix(mean(mfcc_test(:, find(ind == 4)), 2));  %计算第二列码本
% x = disteu(mfcc_test(:, find(ind == 4)), r(:, 4));
% for q = 1:length(x)
%     t = t + x(q);
% end
% 
% if (((drp - t)/t) < e)
%     c=1;
% else
%     c=0;
% end
% 
% 
% %第三次计算4个码本
% drp=t;   %存储一下值
% t=0;
% z = disteu(mfcc_test, r);
% [m,ind] = min(z, [], 2);
% t=0;
% c=0;
% r(:, 1) = fix(mean(mfcc_test(:, find(ind == 1)), 2));%计算第一列码本
% x = disteu(mfcc_test(:, find(ind == 1)), r(:, 1));
% for q = 1:length(x)
%     t = t + x(q);
% end
% 
% r(:, 2) = fix(mean(mfcc_test(:, find(ind == 2)), 2));%计算第一列码本
% x = disteu(mfcc_test(:, find(ind == 2)), r(:, 2));
% for q = 1:length(x)
%     t = t + x(q);
% end
% 
% r(:, 3) = fix(mean(mfcc_test(:, find(ind == 3)), 2));  %计算第二列码本
% x = disteu(mfcc_test(:, find(ind == 3)), r(:, 3));
% for q = 1:length(x)
%     t = t + x(q);
% end
% 
% r(:, 4) = fix(mean(mfcc_test(:, find(ind == 4)), 2));  %计算第二列码本
% x = disteu(mfcc_test(:, find(ind == 4)), r(:, 4));
% for q = 1:length(x)
%     t = t + x(q);
% end
% 
% if (((drp - t)/t) < e)
%     c=1;
% else
%     c=0;
% end

r2=vqlbg(floor(r2),16);



[row, col] = size(r3); % 获取矩阵的行数和列数
B = reshape(r3, row * col, 1); % 将矩阵展开为列向量
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


