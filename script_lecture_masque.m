clear all;
close all;
nb_images = 36; % Nombre d'images

% chargement des images
for i = 1:nb_images
    if i<=10
        nom = sprintf('images/viff.00%d.ppm',i-1);
    else
        nom = sprintf('images/viff.0%d.ppm',i-1);
    end;
    % L'ensemble des images de taille : nb_lignes x nb_colonnes x nb_canaux
    % x nb_images
    im(:,:,:,i) = imread(nom); 
end;
% chargement des masques (pour l'elimination des fonds bleus)
% de taille nb_lignes x nb_colonnes x nb_images
load mask;
fprintf('Chargement des donnees termine\n');

% Affichage des images
figure; 
subplot(2,2,1); imshow(im(:,:,:,1)); title('Image 1');
subplot(2,2,2); imshow(im(:,:,:,9)); title('Image 9');
subplot(2,2,3); imshow(im(:,:,:,17)); title('Image 17');
subplot(2,2,4); imshow(im(:,:,:,25)); title('Image 25');

% Affichage des masques associes
figure;
subplot(2,2,1); imshow(im_mask(:,:,1)); title('Masque image 1');
subplot(2,2,2); imshow(im_mask(:,:,9)); title('Masque image 9');
subplot(2,2,3); imshow(im_mask(:,:,17)); title('Masque image 17');
subplot(2,2,4); imshow(im_mask(:,:,25)); title('Masque image 25');

