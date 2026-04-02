clear;
close all;
load mask;
% Nombre d'images utilisees
nb_images = 36; 
k = 100;
% chargement des images
for i = 1:nb_images
    if i<=10
        nom = sprintf('images/viff.00%d.ppm',i-1);
    else
        nom = sprintf('images/viff.0%d.ppm',i-1);
    end
    % im est une matrice de dimension 4 qui contient 
    % l'ensemble des images couleur de taille : nb_lignes x nb_colonnes x nb_canaux 
    % im est donc de dimension nb_lignes x nb_colonnes x nb_canaux x nb_images
    im(:,:,:,i) = imread(nom); 
end

% Affichage des images
figure; 
subplot(2,2,1); imshow(im(:,:,:,1)); title('Image 1');
subplot(2,2,2); imshow(im(:,:,:,9)); title('Image 9');
subplot(2,2,3); imshow(im(:,:,:,17)); title('Image 17');
subplot(2,2,4); imshow(im(:,:,:,25)); title('Image 25');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% A COMPLETER                                             %
% Calculs des superpixels                                 % 
% Conseil : afficher les germes + les régions             %
% à chaque étape / à chaque itération                     %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
[nb_ligne, nb_col, nb_canaux] = size(im(:,:,:,1));


S = round((sqrt(nb_ligne*nb_col/k)));  % Size d'un superpixel
Nb_lignes = floor(nb_ligne / S);
Nb_col = floor(nb_col / S);

N_centre = Nb_lignes * Nb_col;

gk = zeros(N_centre,5);  % Centres des superpixels l a b x y sous forme de liste
labels = zeros(nb_ligne,nb_col);  % Centre associés à chaque pixel


m = 10;
seuil = 10;
max_iter = 20;

[taille,~,~] = size(gk);

for i = 1:nb_images             %%%  Pour chaque images
    image = im(:,:,:,i);
    indice = 1;
    for row = 1:Nb_lignes       % On itère sur chaque pixel(row,col) qui va être un centre 
        for col = 1:Nb_col
            lg = round(S/2 + (row-1)*S);
            cl = round(S/2 + (col-1)*S);

            image_pix = image(lg,cl,:);  % On récupère les valeurs du centre(indice) de l'image (lg,cl)
            l = image_pix(1);
            a = image_pix(2);
            b = image_pix(3);
            gk(indice,:) = [l,a,b,lg,cl];

            indice = indice + 1;
        end
    end

    N_centre = indice - 1;
    gk = gk(1:N_centre, :);
    
    E = 100;
    iter = 0;

    while E > seuil && iter < max_iter
        iter = iter + 1;
        labels = zeros(nb_ligne,nb_col);
        labels = labels - 1;
        dist = zeros(nb_ligne,nb_col);
        dist = dist + Inf;

        for idx = 1:N_centre %%%%%% each center centre
            centre = gk(idx,:);
            centre_x = centre(4);
            centre_y = centre(5);

            row_min = max(1, floor(centre_x - 2*S));
            row_max = min(nb_ligne, ceil(centre_x + 2*S));
            col_min = max(1, floor(centre_y - 2*S));
            col_max = min(nb_col, ceil(centre_y + 2*S));
                         
            for lg=row_min:row_max   %%%%%% for each pixel (lg,col) neighbour to centre in window 2*S
                for col=col_min:col_max
                    if lg~=centre_x && col~=centre_y     %%%%%% exclude pixel centre
                        image_loc = image(lg,col,:);
                        %%% Distance en couleur
                        Da = (image_loc(1) - centre(1))^2;
                        Da = Da + (image_loc(2) - centre(2))^2;
                        Da = Da + (image_loc(3) - centre(3))^2;
                        %%% Distance en position
                        Dp = (lg - centre(4))^2;
                        Dp = Dp + (col - centre(5))^2;
                        Dp = (m/S)^2 * Dp;
                        %%% Distance
                        D = sqrt(double(Da^2 + Dp^2));
                        if D < dist(lg,col)
                            dist(lg,col) = D;
                            labels(lg,col) = idx;
                        end 
                    end
                end
            end
        end 
        %%% On utilise les distance et les labels trouves pour modifier les
        %%% centres
        nouv_centre = zeros(N_centre, 5);

        % Compute new cluster centers.
        for c = 1:N_centre 
            % Trouver tous les pixels appartenant à ce cluster
            mask = (labels == c);
            nb_pix = sum(mask(:));
            
            if nb_pix > 0
                % Calcul de la moyenne (L, a, b, y, x)
                l_im = image(:,:,1);
                a_im = image(:,:,2);
                b_im = image(:,:,3);
                sum_l = sum(double(l_im(mask)));
                sum_a = sum(double(a_im(mask)));
                sum_b = sum(double(b_im(mask)));
                
                [ys, xs] = find(mask);
                sum_y = sum(ys);
                sum_x = sum(xs);
                
                nouv_centre(c, :) = [sum_l/nb_pix, sum_a/nb_pix, sum_b/nb_pix, ...
                                     sum_y/nb_pix, sum_x/nb_pix];
            else
                % Si cluster vide, on garde l'ancien centre
                nouv_centre(c, :) = gk(c, :);
            end
        end
        if mod(iter, 2) == 0 || iter == 1
            
            % 1. Créer une image de labels indexés (valeurs de 1 à N_centre)
            % On utilise 'uint16' pour être sûr de supporter jusqu'à 65535 superpixels
            label_image = uint16(labels + 2); % +2 pour éviter le 0 (noir) et -1
            
            % Générer une colormap
            cmap = hsv(N_centre + 2); 
            
            % Convertir les labels en RGB correctement
            rgb_vis = ind2rgb(label_image, cmap);
            
            % Remettre les pixels non assignés (-1) en noir si nécessaire
            % (ind2rgb gère déjà les indices, mais nos labels -1 sont devenus 1)
            % Si vous voulez que le fond non assigné soit noir :
            mask_unassigned = (labels == -1);
            rgb_vis(repmat(mask_unassigned, [1, 1, 3])) = 0;

            figure(100 + i); 
            clf; 
            
            subplot(1, 2, 1);
            imshow(rgb_vis);
            title(sprintf('Itération %d : Régions', iter));
            axis off;
            
            % 2. Afficher les germes sur l'image originale
            subplot(1, 2, 2);
            imshow(image); 
            hold on;
            % Utilisation des NOUVEAUX centres (nouv_centre) pour voir le mouvement
            % Vérification que les centres sont bien dans l'image
            valid_centers = (nouv_centre(:,4) >= 1) & (nouv_centre(:,4) <= nb_ligne) & ...
                            (nouv_centre(:,5) >= 1) & (nouv_centre(:,5) <= nb_col);
            
            plot(nouv_centre(valid_centers, 5), nouv_centre(valid_centers, 4), ...
                 'r+', 'MarkerSize', 8, 'LineWidth', 1.5);
            title(sprintf('Itération %d : Germes (k=%d)', iter, N_centre));
            axis off;
            hold off;
            
            drawnow; 
        end
        % Compute residual error E.
        E = sqrt(sum((nouv_centre - gk).^2, 'all'));
        
        % Mise à jour pour prochaine itération
        gk = nouv_centre;

        
    end 
% ........................................................%


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% A COMPLETER                                             %
% Binarisation de l'image à partir des superpixels        %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    gray_image = rgb2gray(image);
    gk_gray = gray_image([gk(:,4),gk(:,5)]);
    [h,~] = imhist(gk_gray,16);
    T = otsuthresh(h);
    Bw = imbinarize(image,T);
    Bw = single(Bw);
    figure;
    imshow(Bw);
    


% ........................................................%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% A FAIRE SI VOUS UTILISEZ LES MASQUES BINAIRES FOURNIS   %
% Chargement des masques binaires                         %
% de taille nb_lignes x nb_colonnes x nb_images           %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% ... 
    im_binaire = im_mask(:,:,i);

    contour = bwtraceboundary(Bw,[0 0],'W');
    plot(contour(:,2),contour(:,1),'g','LineWidth',2);

end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% A DECOMMENTER ET COMPLETER                              %
% quand vous aurez les images segmentées                  %
% Affichage des masques associes                          %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
figure;
subplot(2,2,1); imshow(im_mask(:,:,1)); title('Masque image 1');
subplot(2,2,2); imshow(im_mask(:,:,9)) ; title('Masque image 9');
subplot(2,2,3); imshow(im_mask(:,:,17)) ; title('Masque image 17');
subplot(2,2,4); imshow(im_mask(:,:,25)) ; title('Masque image 25');

% chargement des points 2D suivis 
% pts de taille nb_points x (2 x nb_images)
% sur chaque ligne de pts 
% tous les appariements possibles pour un point 3D donne
% on affiche les coordonnees (xi,yi) de Pi dans les colonnes 2i-1 et 2i
% tout le reste vaut -1
pts = load('viff.xy');
% Chargement des matrices de projection
% Chaque P{i} contient la matrice de projection associee a l'image i 
% RAPPEL : P{i} est de taille 3 x 4
load dino_Ps;

% Reconstruction des points 3D
X = []; % Contient les coordonnees des points en 3D
color = []; % Contient la couleur associee
% Pour chaque couple de points apparies
for i = 1:size(pts,1)
    % Recuperation des ensembles de points apparies
    l = find(pts(i,1:2:end)~=-1);
    % Verification qu'il existe bien des points apparies dans cette image
    if size(l,2) > 1 & max(l)-min(l) > 1 && max(l)-min(l) < 36
        A = [];
        R = 0;
        G = 0;
        B = 0;
        % Pour chaque point recupere, calcul des coordonnees en 3D
        for j = l
            A = [A;P{j}(1,:)-pts(i,(j-1)*2+1)*P{j}(3,:);
            P{j}(2,:)-pts(i,(j-1)*2+2)*P{j}(3,:)];
            R = R + double(im(int16(pts(i,(j-1)*2+1)),int16(pts(i,(j-1)*2+2)),1,j));
            G = G + double(im(int16(pts(i,(j-1)*2+1)),int16(pts(i,(j-1)*2+2)),2,j));
            B = B + double(im(int16(pts(i,(j-1)*2+1)),int16(pts(i,(j-1)*2+2)),3,j));
        end
        [U,S,V] = svd(A);
        X = [X V(:,end)/V(end,end)];
        color = [color [R/size(l,2);G/size(l,2);B/size(l,2)]];
    end
end
fprintf('Calcul des points 3D termine : %d points trouves. \n',size(X,2));

%affichage du nuage de points 3D
figure;
hold on;
for i = 1:size(X,2)
    plot3(X(1,i),X(2,i),X(3,i),'.','col',color(:,i)/255);
end
axis equal;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% A COMPLETER                  %
% Tetraedrisation de Delaunay  %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% T = ...                      

% A DECOMMENTER POUR AFFICHER LE MAILLAGE
 fprintf('Tetraedrisation terminee : %d tetraedres trouves. \n',size(T,1));
% Affichage de la tetraedrisation de Delaunay
 figure;
 tetramesh(T);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% A DECOMMENTER ET A COMPLETER %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Calcul des barycentres de chacun des tetraedres
% poids = ... 
% nb_barycentres = ... 
% for i = 1:size(T,1)
    % Calcul des barycentres differents en fonction des poids differents
    % En commencant par le barycentre avec poids uniformes
%     C_g(:,i,1)=[ ...

% A DECOMMENTER POUR VERIFICATION 
% A RE-COMMENTER UNE FOIS LA VERIFICATION FAITE
% Visualisation pour vérifier le bon calcul des barycentres
% for i = 1:nb_images
%    for k = 1:nb_barycentres
%        o = P{i}*C_g(:,:,k);
%        o = o./repmat(o(3,:),3,1);
%        imshow(im_mask(:,:,i));
%        hold on;
%        plot(o(2,:),o(1,:),'rx');
%        pause;
%        close;
%    end
%end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% A DECOMMENTER ET A COMPLETER %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copie de la triangulation pour pouvoir supprimer des tetraedres
% tri=T.Triangulation;
% Retrait des tetraedres dont au moins un des barycentres 
% ne se trouvent pas dans au moins un des masques des images de travail
% Pour chaque barycentre
% for k=1:nb_barycentres
% ...

% A DECOMMENTER POUR AFFICHER LE MAILLAGE RESULTAT
% Affichage des tetraedres restants
% fprintf('Retrait des tetraedres exterieurs a la forme 3D termine : %d tetraedres restants. \n',size(Tbis,1));
% figure;
% trisurf(tri,X(1,:),X(2,:),X(3,:));

% Sauvegarde des donnees
% save donnees;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% CONSEIL : A METTRE DANS UN AUTRE SCRIPT %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% load donnees;
% Calcul des faces du maillage à garder
% FACES = ...;
% ...

% fprintf('Calcul du maillage final termine : %d faces. \n',size(FACES,1));

% Affichage du maillage final
% figure;
% hold on
% for i = 1:size(FACES,1)
%    plot3([X(1,FACES(i,1)) X(1,FACES(i,2))],[X(2,FACES(i,1)) X(2,FACES(i,2))],[X(3,FACES(i,1)) X(3,FACES(i,2))],'r');
%    plot3([X(1,FACES(i,1)) X(1,FACES(i,3))],[X(2,FACES(i,1)) X(2,FACES(i,3))],[X(3,FACES(i,1)) X(3,FACES(i,3))],'r');
%    plot3([X(1,FACES(i,3)) X(1,FACES(i,2))],[X(2,FACES(i,3)) X(2,FACES(i,2))],[X(3,FACES(i,3)) X(3,FACES(i,2))],'r');
% end;
