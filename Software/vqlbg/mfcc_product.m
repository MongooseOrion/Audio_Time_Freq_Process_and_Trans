load('mfcc.mat','r');
r2 = floor(r);
% t=0;
% % �������Ϊ A
% r1 = r(:, 1:300);
% r = r1;
% e = 3/127;
% mfcc_test = floor(r);
% mean1 = fix(mean(mfcc_test,2));
% r = [mean1+floor(e*mean1),mean1-floor(e*mean1)];
% z = disteu(mfcc_test, r);
% [m,ind] = min(z, [], 2);
% 
% r(:, 1) = fix(mean(mfcc_test(:, find(ind == 1)), 2));%�����һ���뱾
% x = disteu(mfcc_test(:, find(ind == 1)), r(:, 1));
% for q = 1:length(x)
%     t = t + x(q);
% end
% 
% r(:, 2) = fix(mean(mfcc_test(:, find(ind == 2)), 2));  %����ڶ����뱾
% x = disteu(mfcc_test(:, find(ind == 2)), r(:, 2));
% for q = 1:length(x)
%     t = t + x(q);
% end
% drp=t;   %�洢һ��ֵ
% t=0;
% z = disteu(mfcc_test, r);
% [m,ind] = min(z, [], 2);
% 
% r(:, 1) = fix(mean(mfcc_test(:, find(ind == 1)), 2));%�ڶ��μ����һ���뱾
% x = disteu(mfcc_test(:, find(ind == 1)), r(:, 1));
% for q = 1:length(x)
%     t = t + x(q);
% end
% 
% r(:, 2) = fix(mean(mfcc_test(:, find(ind == 2)), 2));  %�ڶ��μ���ڶ����뱾
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
% r = [r+floor(e*r),r-floor(e*r)];  %���ѳ�4��
% z = disteu(mfcc_test, r);
% [m,ind] = min(z, [], 2);
% t=0;
% r(:, 1) = fix(mean(mfcc_test(:, find(ind == 1)), 2));%�����һ���뱾
% x = disteu(mfcc_test(:, find(ind == 1)), r(:, 1));
% for q = 1:length(x)
%     t = t + x(q);
% end
% 
% r(:, 2) = fix(mean(mfcc_test(:, find(ind == 2)), 2));%�����һ���뱾
% x = disteu(mfcc_test(:, find(ind == 2)), r(:, 2));
% for q = 1:length(x)
%     t = t + x(q);
% end
% 
% r(:, 3) = fix(mean(mfcc_test(:, find(ind == 3)), 2));  %����ڶ����뱾
% x = disteu(mfcc_test(:, find(ind == 3)), r(:, 3));
% for q = 1:length(x)
%     t = t + x(q);
% end
% 
% r(:, 4) = fix(mean(mfcc_test(:, find(ind == 4)), 2));  %����ڶ����뱾
% x = disteu(mfcc_test(:, find(ind == 4)), r(:, 4));
% for q = 1:length(x)
%     t = t + x(q);
% end
% 
% 
% %�ڶ��μ���ڶ���
% drp=t;   %�洢һ��ֵ
% t=0;
% z = disteu(mfcc_test, r);
% [m,ind] = min(z, [], 2);
% t=0;
% r(:, 1) = fix(mean(mfcc_test(:, find(ind == 1)), 2));%�����һ���뱾
% x = disteu(mfcc_test(:, find(ind == 1)), r(:, 1));
% for q = 1:length(x)
%     t = t + x(q);
% end
% 
% r(:, 2) = fix(mean(mfcc_test(:, find(ind == 2)), 2));%�����һ���뱾
% x = disteu(mfcc_test(:, find(ind == 2)), r(:, 2));
% for q = 1:length(x)
%     t = t + x(q);
% end
% 
% r(:, 3) = fix(mean(mfcc_test(:, find(ind == 3)), 2));  %����ڶ����뱾
% x = disteu(mfcc_test(:, find(ind == 3)), r(:, 3));
% for q = 1:length(x)
%     t = t + x(q);
% end
% 
% r(:, 4) = fix(mean(mfcc_test(:, find(ind == 4)), 2));  %����ڶ����뱾
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
% %�����μ���4���뱾
% drp=t;   %�洢һ��ֵ
% t=0;
% z = disteu(mfcc_test, r);
% [m,ind] = min(z, [], 2);
% t=0;
% c=0;
% r(:, 1) = fix(mean(mfcc_test(:, find(ind == 1)), 2));%�����һ���뱾
% x = disteu(mfcc_test(:, find(ind == 1)), r(:, 1));
% for q = 1:length(x)
%     t = t + x(q);
% end
% 
% r(:, 2) = fix(mean(mfcc_test(:, find(ind == 2)), 2));%�����һ���뱾
% x = disteu(mfcc_test(:, find(ind == 2)), r(:, 2));
% for q = 1:length(x)
%     t = t + x(q);
% end
% 
% r(:, 3) = fix(mean(mfcc_test(:, find(ind == 3)), 2));  %����ڶ����뱾
% x = disteu(mfcc_test(:, find(ind == 3)), r(:, 3));
% for q = 1:length(x)
%     t = t + x(q);
% end
% 
% r(:, 4) = fix(mean(mfcc_test(:, find(ind == 4)), 2));  %����ڶ����뱾
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



[row, col] = size(r3); % ��ȡ���������������
B = reshape(r3, row * col, 1); % ������չ��Ϊ������
% ���ԭ������Ԫ��Ϊ��������ת����Ķ������ַ���ǰ����ϸ���
result2 = strings(length(B), 1); % ��ʼ�� result2��ȷ����С�� result1 ��ͬ
for i = 1:length(B)
     result2(i) = twos_complement(B(i), 9);
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


