function [] = SpiriVis_frames(E)          
% Figure keypressfcn
S.fh = figure('units','normalized','outerposition',[0 0 1 1],'keypressfcn',@fh_kpfcn);
SpiriVis_Static(vlookup(ttotal,Tc_act),ttotal,Xtotal,'C3',wall_loc,'YZ',pint11_hist,pint12_hist,pc_w1_hist,pint21_hist,pint22_hist,pc_w2_hist,pc_w3_hist,pc_w4_hist,Tc_act)

guidata(S.fh,S) 
end