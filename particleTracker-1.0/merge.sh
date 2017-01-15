#!/bin/bash 
# Script to merge interactively after doing git merge --no-commit
# Adapted from http://stackoverflow.com/questions/10935226/git-interactive-merge

filename="linkFeaturesKalmanSparse";
path="u-track111221/u-track/" 				# Path from repo root

git show HEAD:$path$filename".m" > $filename".HEAD";
git show v2.1.1_2:$path$filename".m" > $filename".branch";
# This is the base branch, if it's the same as HEAD don't use it.
#git show `git merge-base HEAD v2.1.1_2`:$path$filename".m" > $filename".base"  

#meld $filename.{HEAD,branch,base}
meld $filename.{HEAD,branch}


# Files that I modified
# linkFeaturesKalmanSparse.m 		
# trackCloseGapsKalmanSparse.m 	
# overlayTracksMovieNew.m 		
# make_tracks_movie.m 			
# movieInfrastructure.m 			
# coordAmpMatFromIndicesSparse.m 	
# plotTrack2D.m