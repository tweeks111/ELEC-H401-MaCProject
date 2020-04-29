function u = softDecoding(codeword,H,variance,maxIter)

    % H = N-K*N = r*c
[r,c] = size(H);

Lc=-2*codeword/variance;
Lq= zeros(r,c);
for j=1:c
   Lq(:,j)=Lc(j);
end
LQ = zeros(1,c);
u=codeword;
iter=0;
while(sum(mod(u*H',2))~=0 && iter<maxIter)
    Lr = zeros(r,c);
    % STEP 1 : Calcule response of the c-nodes for every v-node
    for i = 1:r
        v_nodes_index = find(H(i,:));
        for idx = 1:length(v_nodes_index)
            index=v_nodes_index;
            index(idx)=[];
            Lr(i,idx)= prod(sign(Lq(index)))*min(abs(Lq(index)));
        end
    end
    % STEP 2 :  Update check nodes
    for j=1:c
        c_nodes_index = find(H(:,j)); % ??
        for idx =1:length(c_nodes_index)
            index = c_nodes_index;
            index(idx)=[];
            Lq(idx,j)=Lc(i)+sum(Lr(index,i));
            
        end
        LQ(j)=Lc(j)+sum(Lr(c_nodes_index,j));
        if(LQ(j)<0)
            u(j)=1;
        else
            u(j)=0;
        end
    end
    iter=iter+1;
end

% disp("iter =");
% disp(iter-1);

end