/*
 Use DSCIR
 Import Perkins Preliminary Participants File into a table called perkins_participants_ACYR (1920)
 */

SELECT pa_year,
       pa_inst_type,
       pa_inst_retained,
       pa_banner_id,
       pa_id,
       pa_ssid,
       pa_last,
       pa_first,
       pa_middle,
       pa_gender,
       pa_max_grade_level,
       pa_ipeds_ethnicity,
       pa_prev_conc,
       pa_pell,
       pa_bia,
       pa_wiadws,
       pa_pell_amount,
       pa_bia_amount,
       pa_disabled,
       pa_economically_disadvantaged,
       pa_ell,
       pa_single_parent
  FROM perkins_participants_1920;

/* Run Updates to populate missing columns */

UPDATE perkins_participants_1920
   SET pa_economically_disadvantaged = '1'
 WHERE pa_economically_disadvantaged IS NULL
   AND pa_banner_id IN (SELECT b.spriden_id
                          FROM tbraccd@proddb a
                               LEFT JOIN spriden@proddb b
                                         ON b.spriden_pidm = a.tbraccd_pidm
                         WHERE b.spriden_change_ind IS NULL
                           AND a.tbraccd_term_code BETWEEN '201930' AND '202020'
                           AND (UPPER(a.tbraccd_desc) LIKE '%WORKFORCE%' OR a.tbraccd_detail_code IN 'PELL')
                           AND a.tbraccd_amount > 0);

UPDATE perkins_participants_1920
   SET pa_ell = '1'
 WHERE pa_banner_id IN (SELECT b.spriden_id
                          FROM shrtckn@proddb a
                               LEFT JOIN spriden@proddb b
                                         ON b.spriden_pidm = a.shrtckn_pidm
                         WHERE b.spriden_change_ind IS NULL
                           AND a.shrtckn_subj_code IN ('ESL', 'ESOL'))
    OR pa_banner_id IN (SELECT b.spriden_id
                          FROM sortest@proddb a
                               LEFT JOIN spriden@proddb b
                                         ON b.spriden_pidm = a.sortest_pidm
                         WHERE a.sortest_tesc_code IN
                               ('T01', 'T02', 'T03', 'T04', 'T05', 'MLB1', 'MLB2', 'MLB3', 'MLB4',
                                'DSL1', 'DSL2', 'DSL3', 'IBTL', 'IBTR', 'IBTS', 'IBTT', 'IBTW')
                           AND b.spriden_change_ind IS NULL);

/*********************************************************************
  PA_DISABLED
  INSERT HERE
  *******************************************************************/

UPDATE perkins_participants_1920
   SET pa_single_parent = '1'
 WHERE pa_banner_id IN (SELECT c.spriden_id
                          FROM rcrapp1@proddb a
                               INNER JOIN rcrapp2@proddb b
                                          ON b.rcrapp2_aidy_code = a.rcrapp1_aidy_code AND
                                             b.rcrapp2_infc_code = a.rcrapp1_infc_code AND
                                             b.rcrapp2_seq_no = a.rcrapp1_seq_no AND b.rcrapp2_pidm = a.rcrapp1_pidm
                               LEFT JOIN spriden@proddb c
                                         ON c.spriden_pidm = rcrapp1_pidm
                         WHERE a.rcrapp1_aidy_code = '1920'
                           AND b.rcrapp2_model_cde = 'I'
                           AND a.rcrapp1_curr_rec_ind = 'Y'
                           AND a.rcrapp1_fam_memb > '1'
                           AND a.rcrapp1_mrtl_status IN ('1', '3')
                           AND c.spriden_change_ind IS NULL);

/* Need to review this */
UPDATE perkins_participants_1920 a
   SET pa_pell_amount = (SELECT SUM(a1.tbraccd_amount)
                           FROM tbraccd@proddb a1
                                LEFT JOIN sfbetrm@proddb b2
                                          ON b2.sfbetrm_pidm = a1.tbraccd_pidm
                                LEFT JOIN spriden@proddb c2
                                          ON c2.spriden_pidm = a1.tbraccd_pidm
                          WHERE c2.spriden_id = a.pa_banner_id
                            AND a1.tbraccd_detail_code = 'PELL'
                            --AND p_time_status_3 IN ('FT', '3Q', 'HT')
                            AND b2.sfbetrm_ests_code = 'EL'
                            AND b2.sfbetrm_tmst_code != '00'
                            AND a1.tbraccd_term_code IN ('201930', '201940', '202020')
                            AND c2.spriden_change_ind IS NULL)
 WHERE pa_pell_amount IS NOT NULL;

SELECT SUM(a1.tbraccd_amount),
       tbraccd_pidm
  FROM tbraccd@proddb a1
       LEFT JOIN sfbetrm@proddb b2
                 ON b2.sfbetrm_pidm = a1.tbraccd_pidm
       LEFT JOIN spriden@proddb c2
                 ON c2.spriden_pidm = a1.tbraccd_pidm
 WHERE a1.tbraccd_detail_code = 'PELL'
   --AND p_time_status_3 IN ('FT', '3Q', 'HT')
   AND b2.sfbetrm_ests_code = 'EL'
   AND b2.sfbetrm_tmst_code != '00'
   AND a1.tbraccd_term_code IN ('201930', '201940', '202020')
   AND c2.spriden_change_ind IS NULL
   AND spriden_id IN (SELECT pa_banner_id
                        FROM perkins_participants_1920)
 GROUP BY tbraccd_pidm;

/*
 pa_bia
 */


UPDATE perkins_participants_1920
   SET pa_bia = '1'
 WHERE pa_bia IS NULL
   AND EXISTS(SELECT 'X'
                FROM tbraccd@proddb a
                LEFT JOIN spriden@proddb b ON b.spriden_pidm = a.tbraccd_pidm
               WHERE b.spriden_change_ind IS NULL
                 AND b.spriden_id = pa_banner_id
                 AND tbraccd_amount <> 0
                 AND tbraccd_term_code IN ('201930', '201940', '202020')
                 AND tbraccd_detail_code IN ('8933')
                 AND NOT EXISTS(SELECT 'Y'
                                  FROM tbraccd@proddb a1
                                  LEFT JOIN spriden@proddb b1 ON b1.spriden_pidm = a1.tbraccd_pidm
                                 WHERE b1.spriden_change_ind IS NULL
                                   AND b1.spriden_id = pa_banner_id
                                   AND tbraccd_detail_code = 'PELL'
                                   AND tbraccd_amount > 0
                                   AND tbraccd_term_code IN ('201930', '201940', '202020')));

UPDATE perkins_participants_1920
   SET pa_bia_amount = (SELECT sum(tbraccd_amount)
                      FROM tbraccd@proddb a
                 LEFT JOIN spriden@proddb b ON b.spriden_pidm = a.tbraccd_pidm
                     WHERE b.spriden_change_ind IS NULL
                       AND b.spriden_id = pa_banner_id
                       AND tbraccd_detail_code = '8933'
                       AND tbraccd_term_code IN ('201930', '201940', '202020'))
 WHERE pa_bia IS NOT NULL;



/*
   Disabled Students
   Need to get a list of disabled students from disability services.  Import into disab_students on PROD
 */

UPDATE perkins_participants_1920
SET pa_disabled = 1
WHERE pa_banner_id IN (SELECT DISTINCT drc_banner_id FROM disab_students@proddb WHERE drc_term_code IN ('201930', '201940', '202020'));

SELECT *
FROM perkins_participants_1920;