### This script outputs a data frame called ´allplays´, a data frame called 
### ´variants´ that indicates character-alias correspondence, a data frame 
### called ´social´ that indicates character-social status correspondence, and
### most importantly, a function that draws a plot with percentage of words
### spoken in each scene for selected characters.


### To use the function, the following libraries must be loaded:
# library(tidyverse)
# library(tidytext)
# library(readxl)
# library(here)
# library(ndjson)
# library(fs)
# library(colorspace)

### And p017-functions.R must be sourced using
# source(here("src/p017-functions.R"))

### If the function returns this error: 
### my_speakers %in% allplays$speaker are not all TRUE
### It means that one of the characters passed to the function are not in any
### of the plays. Check for misspelling and remember to use small letters only.

# Load all plays
allplays <- read_plays_jsonl(here("data")) %>%
  # add year to Artaxerxes
  mutate(title = if_else(title == "ARTAXERXES", "Artaxerxes", title)) %>% 
  mutate(year = if_else(title == "Artaxerxes", "(1754)", year)) %>% 
  # add column containing both tidy title and year
  mutate(title_year = paste(title, year))

# Load the excel sheet with variantions of character-names
variants <- read_excel(here("data", "Rolleliste.xlsx")) %>% 
  unnest_tokens(variant, Alias, token = "regex", pattern = ", ") %>% 
  mutate(
    Karakter = tolower(Karakter),
    variant = tolower(variant))

# Load the excel sheet with social status
social <- read_excel(here("data", "gender_AND_Mask_alaw_sammenlagte_karakterer_reduceret_i_kategoriantal.xlsx"))
social <- unite(data = social, col = "social_status", "social status, main character", "social status, other characters", sep="", na.rm = TRUE) %>% 
  mutate(social_status = gsub("^NA", "", social_status)) %>% 
  mutate(social_status = gsub("NA$", "", social_status))

# Use the variants object to rename certain speakers in allplays and add social status
allplays <- allplays %>%
  mutate(speaker = tolower(speaker)) %>% 
  left_join(variants, by = c("filename"="Filnavn", "speaker"="variant")) %>% 
  mutate(speaker = if_else(!is.na(Karakter), Karakter, speaker)) %>% 
  mutate(docTitle = tolower(docTitle)) %>% 
  left_join(social[,c(1,2,7)], by = c("docTitle"="play", "speaker"="speaker"))

# THE PLOTTING FUNCTION
percentage_plot <- function(group1=c(), group2=c(), group3=c(), group4=c(), group5=c(), group6=c(), group7=c(), group8=c(), group9=c(), group10=c(), group11=c(), group12=c(),
                           color1=NA, color2=NA, color3=NA, color4=NA, color5=NA, color6=NA, color7=NA, color8=NA, color9=NA, color10=NA, color11=NA, color12=NA){
  
  # COMBINE SPEAKERS AND COLORS INTO VECTORS
  my_speakers <- c(group1, group2, group3, group4, group5, group6, group7, group8, group9, group10, group11, group12)
  
  my_colors <- c(color1, color2, color3, color4, color5, color6, color6, color8, color9, color10, color11, color12) %>% na.omit()
  
  my_plays <- unique(allplays$docTitle[allplays$speaker %in% my_speakers])
  
  # CHECK INPUT
  stopifnot(my_speakers %in% allplays$speaker)
  
  # PREPARE A DATA FRAME FOR PLOTTING
  df <- allplays %>% 
    
    # Remove rows that are not dialogue
    filter(act != "", scene != "", speaker != "", !is.na(speaker), !is.na(spoke)) %>%
    
    # Keep only plays of interest
    filter(docTitle %in% my_plays) %>% 
    
    # Add the number of spoken words
    mutate(n_spoken_words = str_count(spoke, '\\w+')) %>% 
    
    # Organize dataset by grouping
    group_by(year, title_year, act_number, scene_number, speaker) %>% 
    
    # Sum the words spoken by each speaker
    summarise(words = sum(n_spoken_words))
  
  # Find highest number of scenes within each act for use in the plot  
  intercepts <- df %>% group_by(act_number) %>% 
    summarise(max_scene = max(scene_number)) %>% 
    mutate(intercepts = cumsum(max_scene+c(0.5,rep(0,length(act_number)-1)))) %>%
    pull(intercepts)
  
  # Make order of plays chronological   
  play_chronology <- unique(df$title_year)
  df$title_year <- factor(df$title_year, levels = play_chronology)
  
  # Continue preparing data frame
  df <- df %>%   
    # calculate percentage of words spoken in each scene
    group_by(title_year) %>% mutate(percent = 100*(words/sum(words))) %>%
    ungroup() %>% 
    
    # Add act:scene column
    mutate(act_scene = paste0(act_number, ":", str_pad(scene_number, 2, pad = "0")))
  
  # Make group names into text that can be showed in the plot legend
  for (i in 1:12){
    text <- paste(eval(parse(text = paste0("group", i))), collapse = ", ")
    assign(paste0("group", i, "text"), text)
  }
  
  # Make a column that indicates group
  df$group <- "other"
  
  for (i in 1:12){
    df$group <- ifelse(df$speaker %in% eval(parse(text = paste0("group", i))) & df$group=="other", eval(parse(text = paste0("group", i, "text"))), df$group)
  }
  
  groups_used <- c(group12text, group11text, group10text, group9text, group8text, group7text, group6text, group5text, group4text, group3text, group2text, group1text) %>% as_tibble() %>% filter(value != "") %>% pull(value)
  
  df$group <- factor(df$group, levels = c("other", groups_used))
  
  # If two characters from the same group speak in the same scene, their percentages should be added
  df <- df %>% group_by(title_year, act_scene, group) %>% summarise(percent_sum = sum(percent))

  # PLOTTING
  p <- ggplot(df, aes(fill = group, y = percent_sum, x = act_scene)) +
    geom_bar(stat="identity") +
    scale_fill_manual(breaks = c(groups_used[length(groups_used):1], "other"), 
                      values = c(my_colors, "grey")) +
    xlab("Act:Scene") +
    ylab("Percentage of spoken words") +
    facet_grid(rows = vars("title_year" = title_year), 
               switch = "x", scales = "free_y") +
    #scale_y_continuous(breaks = c(0, 50, 100)) +
    geom_vline(xintercept = intercepts, size = 0.2) +
    theme_bw() +
    theme(legend.position = "bottom", 
          legend.title = element_blank(), 
          axis.text.x = element_text(angle = 90, size = 6, hjust = 0, vjust = 0.5),
          axis.text.y = element_text(size = 4),
          strip.text.y = element_text(angle = 0, hjust = 0))
  
  return(p)
}

# THE PLOTTING FUNCTION with social status
percentage_plot_status <- function(group1=c(), group2=c(), group3=c(), group4=c(), group5=c(), group6=c(), group7=c(), group8=c(), group9=c(), group10=c(), group11=c(), group12=c(),
                            color1=NA, color2=NA, color3=NA, color4=NA, color5=NA, color6=NA, color7=NA, color8=NA, color9=NA, color10=NA, color11=NA, color12=NA){
  
  # COMBINE SPEAKERS AND COLORS INTO VECTORS
  my_speakers <- c(group1, group2, group3, group4, group5, group6, group7, group8, group9, group10, group11, group12)
  
  my_colors <- c(color1, color2, color3, color4, color5, color6, color6, color8, color9, color10, color11, color12) %>% na.omit()
  
  my_plays <- unique(allplays$docTitle[allplays$speaker %in% my_speakers])
  
  # CHECK INPUT
  stopifnot(my_speakers %in% allplays$speaker)
  
  # PREPARE A DATA FRAME FOR PLOTTING
  df <- allplays %>% 
    
    # Remove rows that are not dialogue
    filter(act != "", scene != "", speaker != "", !is.na(speaker), !is.na(spoke)) %>%
    
    # Keep only plays of interest
    filter(docTitle %in% my_plays) %>% 
    
    # Add the number of spoken words
    mutate(n_spoken_words = str_count(spoke, '\\w+')) %>% 
    
    # Organize dataset by grouping
    group_by(year, title_year, act_number, scene_number, speaker, social_status) %>% 
    
    # Sum the words spoken by each speaker
    summarise(words = sum(n_spoken_words))
  
  # Find highest number of scenes within each act for use in the plot  
  intercepts <- df %>% group_by(act_number) %>% 
    summarise(max_scene = max(scene_number)) %>% 
    mutate(intercepts = cumsum(max_scene+c(0.5,rep(0,length(act_number)-1)))) %>%
    pull(intercepts)
  
  # Make order of plays chronological   
  play_chronology <- unique(df$title_year)
  df$title_year <- factor(df$title_year, levels = play_chronology)
  
  df <- df %>%   
    # Calculate percentage of words spoken in each scene
    group_by(title_year) %>% mutate(percent = 100*(words/sum(words))) %>% ungroup() %>% 
    
    # Add act:scene column
    mutate(act_scene = paste0(act_number, ":", str_pad(scene_number, 2, pad = "0")))
  
  # Make group names into text that can be showed in the plot legend
  for (i in 1:12){
    text <- paste(eval(parse(text = paste0("group", i))), collapse = ", ")
    assign(paste0("group", i, "text"), text)
  }
  
  # Make a column that indicates group
  df$group <- ifelse(df$social_status=="", "Unknown", df$social_status)
  statuses <- unique(df$social_status)
  
  for (i in 1:12){
    df$group <- ifelse(df$speaker %in% eval(parse(text = paste0("group", i))) & df$social_status %in% statuses, eval(parse(text = paste0("group", i, "text"))), df$group)
  }
  
  groups_used <- c(group12text, group11text, group10text, group9text, group8text, group7text, group6text, group5text, group4text, group3text, group2text, group1text) %>% as_tibble() %>% filter(value != "") %>% pull(value)
  
  statuses_used <- unique(df$group[!df$group %in% groups_used])
  
  df$group <- factor(df$group, levels = c(statuses_used, groups_used))
  
  # If two characters from the same group speak in the same scene, their percentages should be added
  df <- df %>% group_by(title_year, act_scene, group) %>% 
    summarise(percent_sum = sum(percent))
  
  # PLOTTING
  p <- ggplot(df, aes(fill = group, y = percent_sum, x = act_scene)) +
    geom_bar(stat="identity") +
    scale_fill_manual(breaks = c(groups_used[length(groups_used):1], statuses_used), 
                      values = c(my_colors, qualitative_hcl(length(statuses_used), palette = "Set 3"))) +
    xlab("Act:Scene") +
    ylab("Percentage of spoken words") +
    facet_grid(rows = vars("title_year" = title_year), 
               switch = "x", scales = "free_y") +
    geom_vline(xintercept = intercepts, size = 0.2) +
    theme_bw() +
    theme(legend.position = "bottom", 
          legend.title = element_blank(), 
          axis.text.x = element_text(angle = 90, size = 6, hjust = 0, vjust = 0.5),
          axis.text.y = element_text(size = 4),
          strip.text.y = element_text(angle = 0, hjust = 0))
  
  return(p)
}