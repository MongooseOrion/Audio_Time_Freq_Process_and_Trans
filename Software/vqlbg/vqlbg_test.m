load('mfcc.mat','r');
r = floor(r);
r1 = r(:, 1:310);
r1 = reshape(r1, 31, 200); 

r2=vqlbg(floor(r1),8);

r2(isnan(r2)) = 0;
d = disteu(r1, r2);   
dist = sum(min(d,[],2));  %�任�õ�һ���������

[row, col] = size(r1); % ��ȡ���������������
B = reshape(r1, row * col, 1); % ������չ��Ϊ������
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


